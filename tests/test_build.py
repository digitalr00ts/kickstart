"""Exercise the build command without installing packages or creating VMs."""

import io
import os
from pathlib import Path
import subprocess
import tarfile
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class BuildTests(unittest.TestCase):
    def invoke(self, system="Linux", arch="x86_64", args=(), fail="", output="out with spaces", status="Running"):
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            log = directory / "commands"
            shim = directory / "shim"
            shim.write_text('''#!/bin/bash
name=${0##*/}
printf '%s' "$name" >> "$COMMAND_LOG"
printf ' <%s>' "$@" >> "$COMMAND_LOG"
printf '\\n' >> "$COMMAND_LOG"
case "$name" in
  uname) if [[ ${1:-} == -s ]]; then echo "$TEST_SYSTEM"; else echo "$TEST_ARCH"; fi ;;
  uv) [[ $FAIL_COMMAND != uv ]] ;;
  sudo|kiwi-ng) [[ $FAIL_COMMAND != kiwi ]] ;;
  limactl)
    [[ $FAIL_COMMAND != lima ]] || exit 1
    case "$*" in
      *list*) if [[ -n $LIMA_STATUS ]]; then echo "kiwi-builder $LIMA_STATUS"; fi ;;
      *mktemp*) echo /opt/kiwi-build/output/build.test ;;
      *export-image.sh*) tar -cf - --files-from /dev/null ;;
    esac ;;
esac
''')
            shim.chmod(0o755)
            for name in ("uname", "uv", "sudo", "limactl"):
                (directory / name).symlink_to(shim)
            (directory / "environment/bin").mkdir(parents=True)
            (directory / "environment/bin/kiwi-ng").symlink_to(shim)
            env = {**os.environ, "PATH": f"{directory}:{os.environ['PATH']}",
                   "COMMAND_LOG": str(log), "TEST_SYSTEM": system, "TEST_ARCH": arch,
                   "FAIL_COMMAND": fail, "LIMA_STATUS": status, "OUTPUT_DIR": str(directory / output),
                   "UV_PROJECT_ENVIRONMENT": str(directory / "environment")}
            result = subprocess.run(["bash", str(ROOT / "scripts/build.sh"), *args],
                                    cwd=directory, env=env, text=True, capture_output=True, timeout=10)
            return result, log.read_text() if log.exists() else ""

    def test_native_linux_uses_absolute_kiwi_without_sudo_uv(self):
        result, commands = self.invoke()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("<sync> <--group> <build> <--frozen>", commands)
        self.assertTrue("/bin/kiwi-ng>" in commands or "kiwi-ng <--type>" in commands)
        self.assertNotIn("sudo <uv>", commands)
        self.assertIn("out with spaces/x86_64>", commands)

    def test_rejects_cross_architecture_before_sync(self):
        result, commands = self.invoke(args=("44", "aarch64"))
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("uv <sync>", commands)

    def test_dependency_failure_stops_build(self):
        result, commands = self.invoke(fail="uv")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("sudo", commands)

    def test_build_failure_propagates(self):
        result, _ = self.invoke(fail="kiwi")
        self.assertNotEqual(result.returncode, 0)

    def test_macos_exports_from_guest_staging(self):
        result, commands = self.invoke(system="Darwin", arch="arm64")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("<kiwi-builder>", commands)
        self.assertIn("<UV_PROJECT_ENVIRONMENT=/opt/kiwi-build/.venv>", commands)
        self.assertIn("/scripts/export-image.sh> </opt/kiwi-build/output/build.test/aarch64>", commands)
        self.assertIn("out with spaces/aarch64", result.stdout)

    def test_missing_lima_instance_is_created(self):
        result, commands = self.invoke(system="Darwin", arch="arm64", status="")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("<start> <--tty=false> <--name> <kiwi-builder>", commands)

    def test_stopped_lima_instance_is_started(self):
        result, commands = self.invoke(system="Darwin", arch="arm64", status="Stopped")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("<start> <--tty=false> <kiwi-builder>", commands)

    def test_export_contains_only_deliverables(self):
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            (directory / "image.qcow2").write_bytes(b"disk")
            (directory / "image.packages").write_text("kernel")
            (directory / "build/image-root").mkdir(parents=True)
            (directory / "build/image-root/secret").write_text("not a deliverable")
            result = subprocess.run(["bash", str(ROOT / "scripts/export-image.sh"), tmp],
                                    capture_output=True, check=True, timeout=10)
            with tarfile.open(fileobj=io.BytesIO(result.stdout)) as archive:
                self.assertEqual(set(archive.getnames()), {"image.qcow2", "image.packages"})

    def test_export_rejects_ambiguous_or_missing_image(self):
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            for count in (0, 2):
                for index in range(count):
                    (directory / f"image{index}.qcow2").touch()
                result = subprocess.run(["bash", str(ROOT / "scripts/export-image.sh"), tmp],
                                        capture_output=True, timeout=10)
                self.assertNotEqual(result.returncode, 0)

    def test_lima_error_is_not_treated_as_absent(self):
        result, commands = self.invoke(system="Darwin", arch="arm64", fail="lima")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("<start>", commands)

    def test_rejects_unsupported_host(self):
        result, _ = self.invoke(system="FreeBSD")
        self.assertNotEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main()
