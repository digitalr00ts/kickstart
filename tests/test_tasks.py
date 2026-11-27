"""Exercise contributor task dispatch with command shims, without builds or guests."""

import json
import os
import shlex
import shutil
import subprocess
import sys
import tempfile
import tomllib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("mise"), "mise executable is not installed")
class MiseDispatchTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="mise task tests ")
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name).resolve()
        shutil.copyfile(ROOT / "mise.toml", self.directory / "mise.toml")
        with (self.directory / "mise.toml").open("rb") as config:
            tools = tomllib.load(config)["tools"]
        self.log = self.directory / "calls.jsonl"
        bin_directory = self.directory / "bin"
        bin_directory.mkdir()
        recorder = self.directory / "record.py"
        recorder.write_text(
            "import json, os, sys\n"
            "from pathlib import Path\n"
            "call = [Path(sys.argv[1]).name, *sys.argv[2:]]\n"
            "with Path(os.environ['TASK_LOG']).open('a') as log:\n"
            "    log.write(json.dumps(call) + '\\n')\n"
            "sys.exit(23 if call == json.loads(os.environ.get('FAIL_CALL', 'null')) else 0)\n",
            encoding="utf-8",
        )
        for name in ("uv", "node", "prek", "bash"):
            shim = bin_directory / name
            shim.write_text(
                f'#!/bin/sh\nexec {shlex.quote(sys.executable)} {shlex.quote(str(recorder))} "$0" "$@"\n',
                encoding="utf-8",
            )
            shim.chmod(0o755)
        # Ignore inherited mise settings and tools, even when launched via `mise run check`.
        self.env = {key: value for key, value in os.environ.items() if not key.startswith("MISE_")}
        global_config = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))) / "mise"
        self.env.update(
            {
                "HOME": str(self.directory / "home"),
                "XDG_CONFIG_HOME": str(self.directory / "config"),
                "PATH": os.pathsep.join((str(bin_directory), "/usr/bin", "/bin")),
                "MISE_CONFIG_DIR": str(self.directory / "config" / "mise"),
                "MISE_DATA_DIR": str(self.directory / "data"),
                "MISE_CACHE_DIR": str(self.directory / "cache"),
                "MISE_STATE_DIR": str(self.directory / "state"),
                "MISE_IGNORED_CONFIG_PATHS": os.pathsep.join(
                    (
                        str(global_config),
                        str(Path.home() / ".config" / "mise"),
                        os.environ.get("MISE_GLOBAL_CONFIG_FILE", str(global_config / "config.toml")),
                    )
                ),
                "MISE_TRUSTED_CONFIG_PATHS": str(self.directory),
                "MISE_AUTO_INSTALL": "false",
                "MISE_DISABLE_TOOLS": ",".join(tools),
                "MISE_OFFLINE": "true",
                "MISE_TASK_SHELL": "/bin/sh -c",
                "TASK_LOG": str(self.log),
            }
        )
        self.env.pop("FAIL_CALL", None)

    def dispatch(self, task, *args, fail_call=None):
        self.log.unlink(missing_ok=True)
        env = self.env.copy()
        if fail_call is not None:
            env["FAIL_CALL"] = json.dumps(fail_call)
        result = subprocess.run(  # noqa: S603 -- Resolve installed mise; dispatch only controlled tasks and test shims.
            [shutil.which("mise"), "run", task, "--", *args],
            cwd=self.directory,
            env=env,
            capture_output=True,
            text=True,
            timeout=30,
            check=False,
        )
        calls = (
            [json.loads(line) for line in self.log.read_text(encoding="utf-8").splitlines()]
            if self.log.exists()
            else []
        )
        return result, calls

    def test_doctor_forwards_arguments_without_sync(self):
        # The shim checks forwarding, not doctor's validation of scope values.
        for scope in ("test", "scope with spaces"):
            with self.subTest(scope=scope):
                result, calls = self.dispatch("doctor", "--scope", scope)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual(
                    calls, [["uv", "run", "--no-project", "python", "scripts/doctor.py", "--scope", scope]]
                )

    def test_build_preserves_argument_boundaries(self):
        result, calls = self.dispatch("build", "--output-dir", "output with spaces", "--arch", "aarch64")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(
            calls, [["bash", "scripts/build.sh", "--output-dir", "output with spaces", "--arch", "aarch64"]]
        )

    def test_check_all_runs_suites_in_order_and_stops_at_each_failure(self):
        expected = [
            [
                "uv",
                "run",
                "--group",
                "test",
                "--frozen",
                "python",
                "-m",
                "unittest",
                "discover",
                "-s",
                "tests",
                "-p",
                "test_*.py",
            ],
            ["node", "--test", "tests/test_artifact_cleanup.cjs", "tests/test_select_artifact.cjs"],
            [
                "uv",
                "run",
                "--group",
                "test",
                "--frozen",
                "python",
                "-m",
                "unittest",
                "discover",
                "-s",
                ".github/workflows",
                "-p",
                "test_*.py",
            ],
        ]
        result, calls = self.dispatch("check-all")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(calls, expected)
        for index, call in enumerate(expected):
            with self.subTest(failing_suite=call):
                result, calls = self.dispatch("check-all", fail_call=call)
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual(calls, expected[: index + 1])

    def test_guest_test_dispatches_frozen_qemu_scenario_and_propagates_failure(self):
        command = ["uv", "run", "--group", "test", "--frozen", "molecule", "test", "-s", "qemu"]
        result, calls = self.dispatch("test")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(calls, [command])
        result, calls = self.dispatch("test", fail_call=command)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(calls, [command])

    def test_setup_runs_sync_before_hooks_and_stops_on_sync_failure(self):
        sync = ["uv", "sync", "--group", "test", "--frozen"]
        result, calls = self.dispatch("setup")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(calls, [sync, ["prek", "install"]])
        result, calls = self.dispatch("setup", fail_call=sync)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(calls, [sync])

    def test_ansible_lint_forwards_options_and_propagates_failure(self):
        command = ["uv", "run", "--group", "lint", "--frozen", "ansible-lint"]
        result, calls = self.dispatch("lint-ansible")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(calls, [command])
        options = ["-v", "--force-color", "--fix"]
        result, calls = self.dispatch("lint-ansible", *options)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(calls, [command + options])
        result, calls = self.dispatch("lint-ansible", fail_call=command)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(calls, [command])

    def test_lint_only_runs_hooks(self):
        result, calls = self.dispatch("lint")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(calls, [["prek", "run", "--all-files"]])


if __name__ == "__main__":
    unittest.main()
