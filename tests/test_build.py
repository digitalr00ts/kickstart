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
    def invoke(
        self,
        system="Linux",
        arch="x86_64",
        args=(),
        fail="",
        output="out with spaces",
        status="Running",
        occupied="",
        relative_output=False,
        siblings=False,
    ):
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            log = directory / "commands"
            output_root = directory / output
            final = output_root / "aarch64"
            if occupied:
                output_root.mkdir(parents=True)
                if occupied in ("file", "symlink", "dangling"):
                    if occupied == "file":
                        final.write_text("user data")
                    else:
                        target = directory / "user directory"
                        if occupied == "symlink":
                            target.mkdir()
                            (target / "keep").write_text("user data")
                        final.symlink_to(target, target_is_directory=True)
                else:
                    final.mkdir()
                    if occupied != "empty":
                        (final / ".keep").write_text("user data")
            if siblings:
                output_root.mkdir(parents=True, exist_ok=True)
                (output_root / ".aarch64.user-owned").mkdir()
                (output_root / ".aarch64.user-owned/keep").write_text("user data")
                (output_root / "x86_64").mkdir()
                (output_root / "x86_64/keep").write_text("user data")
            archive = directory / "export.tar"
            with tarfile.open(archive, "w") as stream:
                for name, data in (
                    ("image with spaces.qcow2", b"disk" * 1024),
                    ("image with spaces.packages", b"kernel"),
                ):
                    info = tarfile.TarInfo(name)
                    info.size = len(data)
                    stream.addfile(info, io.BytesIO(data))
            if fail == "truncated":
                archive.write_bytes(archive.read_bytes()[:700])
            shim = directory / "shim"
            shim.write_text("""#!/bin/bash
name=${0##*/}
printf '%s' "$name" >> "$COMMAND_LOG"
printf ' <%s>' "$@" >> "$COMMAND_LOG"
printf '\\n' >> "$COMMAND_LOG"
case "$name" in
  uname) if [[ ${1:-} == -s ]]; then echo "$TEST_SYSTEM"; else echo "$TEST_ARCH"; fi ;;
  uv) [[ $FAIL_COMMAND != uv ]] ;;
  sudo|kiwi-ng) [[ $FAIL_COMMAND != kiwi ]] ;;
  mv)
    [[ $FAIL_COMMAND != publish ]] || exit 1
    if [[ $FAIL_COMMAND == publish-race ]]; then
      mkdir -p -- "$OUTPUT_DIR/aarch64"
      printf 'user data' > "$OUTPUT_DIR/aarch64/.keep"
    fi
    exec "$REAL_MV" "$@" ;;
  limactl)
    [[ $FAIL_COMMAND != lima ]] || exit 1
    case "$*" in
      *list*) if [[ -n $LIMA_STATUS ]]; then echo "kiwi-builder $LIMA_STATUS"; fi ;;
      *mktemp*) echo /opt/kiwi-build/output/build.test ;;
      *export-image.sh*)
        if [[ $FAIL_COMMAND == race ]]; then
          mkdir -p -- "$OUTPUT_DIR/aarch64"
          printf 'user data' > "$OUTPUT_DIR/aarch64/.keep"
        fi
        cat "$EXPORT_ARCHIVE"
        [[ $FAIL_COMMAND != export ]] ;;
      *build.sh*) [[ $FAIL_COMMAND != build ]] ;;
      *'sudo rm'*) [[ $FAIL_COMMAND != cleanup ]] ;;
    esac ;;
esac
""")
            shim.chmod(0o755)
            for name in ("uname", "uv", "sudo", "limactl", "mv"):
                (directory / name).symlink_to(shim)
            (directory / "environment/bin").mkdir(parents=True)
            (directory / "environment/bin/kiwi-ng").symlink_to(shim)
            env = {
                **os.environ,
                "PATH": f"{directory}:{os.environ['PATH']}",
                "COMMAND_LOG": str(log),
                "TEST_SYSTEM": system,
                "TEST_ARCH": arch,
                "FAIL_COMMAND": fail,
                "LIMA_STATUS": status,
                "OUTPUT_DIR": output if relative_output else str(output_root),
                "EXPORT_ARCHIVE": str(archive),
                "REAL_MV": "/bin/mv",
                "UV_PROJECT_ENVIRONMENT": str(directory / "environment"),
            }
            result = subprocess.run(
                ["bash", str(ROOT / "scripts/build.sh"), *args],
                cwd=directory,
                env=env,
                text=True,
                capture_output=True,
                timeout=10,
            )
            result.output_files = {
                str(path.relative_to(output_root)): path.read_bytes()
                for path in output_root.rglob("*")
                if path.is_file()
            }
            result.output_entries = sorted(path.name for path in output_root.iterdir()) if output_root.exists() else []
            result.output_symlink = final.is_symlink()
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
        self.assertEqual(
            result.output_files,
            {"aarch64/image with spaces.qcow2": b"disk" * 1024, "aarch64/image with spaces.packages": b"kernel"},
        )
        self.assertEqual(result.output_entries, ["aarch64"])
        self.assertIn("<sudo> <rm> <-rf> <--> </opt/kiwi-build/output/build.test>", commands)

    def test_macos_rejects_occupied_output_before_any_lima_call(self):
        for occupied in ("nonempty", "file", "symlink", "dangling"):
            with self.subTest(occupied=occupied):
                result, commands = self.invoke(system="Darwin", arch="arm64", occupied=occupied, status="Stopped")
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn("limactl", commands)
                self.assertEqual(result.output_entries, ["aarch64"])
                if occupied == "file":
                    self.assertEqual(result.output_files["aarch64"], b"user data")
                elif occupied == "nonempty":
                    self.assertEqual(result.output_files["aarch64/.keep"], b"user data")
                else:
                    self.assertTrue(result.output_symlink)

    def test_macos_accepts_empty_output_directory(self):
        result, _ = self.invoke(system="Darwin", arch="arm64", occupied="empty")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.output_entries, ["aarch64"])
        self.assertEqual(len(result.output_files), 2)

    def test_macos_failures_remove_only_host_staging_and_retain_guest(self):
        for failure in ("build", "export", "truncated", "publish"):
            with self.subTest(failure=failure):
                result, commands = self.invoke(system="Darwin", arch="arm64", fail=failure)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(result.output_entries, [])
                self.assertNotIn("<sudo> <rm>", commands)
                self.assertIn("Guest output retained at /opt/kiwi-build/output/build.test", result.stderr)
                self.assertNotIn("Artifacts:", result.stdout)

    def test_macos_preserves_files_created_during_build(self):
        for failure in ("race", "publish-race"):
            with self.subTest(failure=failure):
                result, commands = self.invoke(system="Darwin", arch="arm64", fail=failure)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(result.output_files, {"aarch64/.keep": b"user data"})
                self.assertEqual(result.output_entries, ["aarch64"])
                self.assertNotIn("<sudo> <rm>", commands)
                self.assertIn("Guest output retained", result.stderr)

    def test_macos_failure_preserves_unowned_siblings(self):
        result, _ = self.invoke(system="Darwin", arch="arm64", fail="truncated", siblings=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.output_files, {".aarch64.user-owned/keep": b"user data", "x86_64/keep": b"user data"})
        self.assertEqual(result.output_entries, [".aarch64.user-owned", "x86_64"])

    def test_macos_preserves_relative_custom_output_with_spaces(self):
        result, _ = self.invoke(system="Darwin", arch="arm64", relative_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.output_entries, ["aarch64"])
        self.assertEqual(len(result.output_files), 2)

    def test_macos_cleanup_failure_is_reported(self):
        result, _ = self.invoke(system="Darwin", arch="arm64", fail="cleanup")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.output_entries, ["aarch64"])
        self.assertEqual(len(result.output_files), 2)
        self.assertIn("Guest output retained", result.stderr)
        self.assertNotIn("Artifacts:", result.stdout)

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
            (directory / "image with spaces.qcow2").write_bytes(b"disk")
            (directory / "image with spaces.packages").write_text("kernel")
            (directory / "build/image-root").mkdir(parents=True)
            (directory / "build/image-root/secret").write_text("not a deliverable")
            result = subprocess.run(
                ["bash", str(ROOT / "scripts/export-image.sh"), tmp], capture_output=True, check=True, timeout=10
            )
            with tarfile.open(fileobj=io.BytesIO(result.stdout)) as archive:
                self.assertEqual(set(archive.getnames()), {"image with spaces.qcow2", "image with spaces.packages"})

    def test_export_rejects_ambiguous_or_missing_image(self):
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            for count in (0, 2):
                for index in range(count):
                    (directory / f"image{index}.qcow2").touch()
                result = subprocess.run(
                    ["bash", str(ROOT / "scripts/export-image.sh"), tmp], capture_output=True, timeout=10
                )
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
