"""Host doctor regressions; never execute host tools, create files or start guests."""

import contextlib
import importlib.util
import io
import os
import subprocess
import sys
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

SPEC = importlib.util.spec_from_file_location("doctor", Path(__file__).resolve().parents[1] / "scripts/doctor.py")
doctor = importlib.util.module_from_spec(SPEC)
previous = sys.dont_write_bytecode
try:
    sys.dont_write_bytecode = True
    SPEC.loader.exec_module(doctor)
finally:
    sys.dont_write_bytecode = previous
vm = doctor.load_helpers()
load_helpers = doctor.load_helpers
firmware = vm.firmware


class DoctorTests(unittest.TestCase):
    def setUp(self):
        patches = {
            "env": patch.dict(os.environ, {}, clear=True),
            "system": patch.object(doctor.platform, "system", return_value="Linux"),
            "machine": patch.object(doctor.platform, "machine", return_value="x86_64"),
            "helpers": patch.object(doctor, "load_helpers", return_value=vm),
            "root": patch.object(doctor, "ROOT", Path("/doctor-home/checkout")),
            "home": patch.object(Path, "home", return_value=Path("/doctor-home")),
            "uid": patch.object(doctor.os, "geteuid", return_value=1000),
            "access": patch.object(doctor.os, "access", return_value=True),
            "which": patch.object(doctor.shutil, "which", side_effect=lambda name: f"/bin/{name}"),
            "firmware": patch.object(vm, "firmware", return_value=(Path("/efi/code"), Path("/efi/vars"))),
            "run": patch.object(
                doctor.subprocess,
                "run",
                return_value=subprocess.CompletedProcess(
                    [], 0, stdout="Accelerators supported in QEMU binary:\nhvf\ntcg\n", stderr=""
                ),
            ),
        }
        for name, patcher in patches.items():
            setattr(self, name, patcher.start())
            self.addCleanup(patcher.stop)
        # Fail immediately if a future doctor starts a process outside the allowlisted probe or writes state.
        for target, name in [
            (subprocess, "Popen"),
            (Path, "write_text"),
            (Path, "write_bytes"),
            (Path, "mkdir"),
            (Path, "touch"),
            (Path, "unlink"),
            (Path, "open"),
        ]:
            patcher = patch.object(target, name, side_effect=AssertionError(f"Forbidden: {name}"))
            patcher.start()
            self.addCleanup(patcher.stop)

    def invoke(self, *args):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            status = doctor.main(list(args))
        return status, output.getvalue()

    def checked_tools(self):
        return {call.args[0] for call in self.which.call_args_list}

    def test_linux_default_checks_all_and_does_not_run_commands(self):
        status, output = self.invoke()
        self.assertEqual(status, 0, output)
        self.assertIn("Summary:", output)
        self.assertIn("0 failed (all)", output)
        self.assertTrue(
            {
                "uv",
                "sudo",
                "dnf5",
                "rpm",
                "mount",
                "umount",
                "chroot",
                "losetup",
                "lsblk",
                "parted",
                "sgdisk",
                "mkfs.btrfs",
                "btrfs",
                "mkfs.vfat",
                "qemu-img",
                "qemu-system-x86_64",
                "ssh",
                "ssh-keygen",
                "virt-customize",
            }
            <= self.checked_tools()
        )
        self.access.assert_called_once_with("/dev/kvm", os.R_OK | os.W_OK)
        self.firmware.assert_called_once_with("x86_64", "/bin/qemu-system-x86_64")
        self.run.assert_not_called()
        for text in (
            "no proof KIWI systemdeps",
            "Lima guest readiness",
            "actual acceleration/boot",
            "docs/building.md",
            "docs/testing.md",
            "No built image is required",
        ):
            self.assertIn(text, output)

    def test_build_scope_root_needs_no_sudo_or_test_tools(self):
        self.uid.return_value = 0
        status, output = self.invoke("--scope", "build")
        self.assertEqual(status, 0, output)
        self.assertNotIn("sudo", self.checked_tools())
        self.assertNotIn("virt-customize", self.checked_tools())
        self.assertNotIn("ssh", self.checked_tools())
        self.access.assert_not_called()
        self.firmware.assert_not_called()
        self.run.assert_not_called()

    def test_test_scope_does_not_require_build_tools(self):
        self.assertEqual(self.invoke("--scope", "test")[0], 0)
        self.assertNotIn("dnf5", self.checked_tools())
        self.assertNotIn("sudo", self.checked_tools())

    def test_missing_tools_all_reported_and_other_checks_continue(self):
        self.which.side_effect = lambda name: None if name in ("uv", "sudo", "ssh") else f"/bin/{name}"
        status, output = self.invoke()
        self.assertEqual(status, 1)
        for tool in ("uv", "sudo", "ssh"):
            self.assertIn(f"FAIL: {tool}:", output)
        self.assertIn("3 failed", output)
        self.assertIn("Install", output)
        self.firmware.assert_called_once()

    def test_macos_native_matrix_and_only_read_only_accelerator_probe(self):
        self.system.return_value = "Darwin"
        for raw, arch in (("arm64", "aarch64"), ("x86_64", "x86_64")):
            with self.subTest(arch=arch):
                self.machine.return_value = raw
                self.which.reset_mock()
                self.run.reset_mock()
                status, output = self.invoke()
                self.assertEqual(status, 0, output)
                self.assertEqual(
                    self.checked_tools(), {"uv", "limactl", "qemu-img", f"qemu-system-{arch}", "ssh", "ssh-keygen"}
                )
                self.run.assert_called_once_with(
                    [f"/bin/qemu-system-{arch}", "-accel", "help"],
                    check=True,
                    timeout=5,
                    stdin=subprocess.DEVNULL,
                    capture_output=True,
                    text=True,
                )
                self.assertIn("not proof it is usable", output)
        self.access.assert_not_called()

    def test_macos_build_only_and_checkout_outside_home(self):
        self.system.return_value = "Darwin"
        with patch.object(doctor, "ROOT", Path("/outside/checkout")):
            status, output = self.invoke("--scope", "build")
        self.assertEqual(status, 1)
        self.assertIn("FAIL: Keep the checkout under home", output)
        self.assertEqual(self.checked_tools(), {"uv", "limactl"})
        self.run.assert_not_called()

    def test_macos_image_path_absolute_under_home_without_existence_check(self):
        self.system.return_value = "Darwin"
        for path, expected in (
            ("/doctor-home/nonexistent.qcow2", 0),
            ("relative.qcow2", 1),
            ("/outside/image.qcow2", 1),
            ("", 1),
            ("/doctor-home/../outside/image.qcow2", 1),
        ):
            with self.subTest(path=path), patch.dict(os.environ, {"IMAGE_PATH": path}):
                status, output = self.invoke("--scope", "test")
                self.assertEqual(status, expected, output)
                self.assertIn("IMAGE_PATH must be absolute and under home", output)

    def test_invalid_acceleration_and_explicit_tcg(self):
        for system, invalid in (("Linux", "hvf"), ("Darwin", "kvm"), ("Linux", ""), ("Darwin", "hvf:tcg")):
            with self.subTest(system=system, accel=invalid), patch.dict(os.environ, {"QEMU_ACCEL": invalid}):
                self.system.return_value = system
                status, output = self.invoke("--scope", "test")
                self.assertEqual(status, 1)
                self.assertIn("FAIL: QEMU_ACCEL", output)
        self.access.reset_mock()
        self.run.reset_mock()
        for system in ("Linux", "Darwin"):
            self.system.return_value = system
            with patch.dict(os.environ, {"QEMU_ACCEL": "tcg"}):
                self.assertEqual(self.invoke("--scope", "test")[0], 0)
        self.access.assert_not_called()
        self.run.assert_not_called()

    def test_linux_kvm_permissions(self):
        self.access.return_value = False
        status, output = self.invoke("--scope", "test")
        self.assertEqual(status, 1)
        self.assertIn("enable /dev/kvm access or set QEMU_ACCEL=tcg", output)
        self.firmware.assert_called_once()

    def test_firmware_failure_and_missing_native_qemu(self):
        self.firmware.side_effect = ValueError("Set both QEMU_EFI_CODE and QEMU_EFI_VARS")
        status, output = self.invoke("--scope", "test")
        self.assertEqual(status, 1)
        self.assertIn("FAIL: EFI:", output)
        self.assertIn("QEMU_EFI_VARS", output)
        self.firmware.reset_mock()
        self.which.side_effect = lambda name: None if name.startswith("qemu-system-") else f"/bin/{name}"
        status, output = self.invoke("--scope", "test")
        self.assertEqual(status, 1)
        self.assertIn("EFI lookup unavailable", output)
        self.firmware.assert_not_called()
        self.run.assert_not_called()

    def test_real_firmware_helper_rejects_partial_or_missing_overrides(self):
        self.firmware.side_effect = firmware
        for overrides in (
            {"QEMU_EFI_CODE": "/missing/code"},
            {"QEMU_EFI_CODE": "/missing/code", "QEMU_EFI_VARS": "/missing/vars"},
        ):
            with (
                self.subTest(overrides=overrides),
                patch.dict(os.environ, overrides),
                patch.object(Path, "is_file", return_value=False),
            ):
                status, output = self.invoke("--scope", "test")
                self.assertEqual(status, 1)
                self.assertIn("FAIL: EFI:", output)
                self.assertIn("QEMU_EFI_CODE", output)
        self.run.assert_not_called()

    def test_linux_arm_alias_uses_native_qemu(self):
        self.machine.return_value = "arm64"
        status, output = self.invoke("--scope", "test")
        self.assertEqual(status, 0, output)
        self.firmware.assert_called_once_with("aarch64", "/bin/qemu-system-aarch64")
        self.assertNotIn("qemu-system-x86_64", self.checked_tools())

    def test_macos_accelerator_query_timeout_failure_and_no_hvf(self):
        self.system.return_value = "Darwin"
        for error in (
            subprocess.TimeoutExpired("qemu", 5),
            subprocess.CalledProcessError(1, "qemu"),
            OSError("cannot execute"),
        ):
            with self.subTest(error=error):
                self.run.side_effect = error
                status, output = self.invoke("--scope", "test")
                self.assertEqual(status, 1)
                self.assertIn("Cannot query QEMU accelerators", output)
                self.assertIn("Summary:", output)
        self.run.side_effect = None
        self.run.return_value.stdout = "tcg\nnot-hvf\n"
        status, output = self.invoke("--scope", "test")
        self.assertEqual(status, 1)
        self.assertIn("install HVF-capable QEMU", output)

    def test_unsupported_os_and_architecture_still_summarize(self):
        self.system.return_value = "Windows"
        status, output = self.invoke()
        self.assertEqual(status, 1)
        self.assertIn("Host OS: Windows", output)
        self.helpers.assert_not_called()
        self.assertEqual(self.checked_tools(), {"uv"})
        self.system.return_value = "Linux"
        self.machine.return_value = "riscv64"
        status, output = self.invoke()
        self.assertEqual(status, 1)
        self.assertIn("Unsupported native architecture", output)
        self.assertIn("Summary:", output)
        self.run.assert_not_called()

    def test_helper_import_disables_bytecode_and_restores_flag_even_on_failure(self):
        spec = MagicMock()
        observed = []
        spec.loader.exec_module.side_effect = lambda _module: observed.append(sys.dont_write_bytecode)
        before = sys.dont_write_bytecode
        with (
            patch.object(doctor.importlib.util, "spec_from_file_location", return_value=spec),
            patch.object(doctor.importlib.util, "module_from_spec", return_value=MagicMock()),
        ):
            load_helpers()
            self.assertEqual(observed, [True])
            self.assertEqual(sys.dont_write_bytecode, before)
            spec.loader.exec_module.side_effect = ImportError("broken helper")
            with self.assertRaises(ImportError):
                load_helpers()
            self.assertEqual(sys.dont_write_bytecode, before)


if __name__ == "__main__":
    unittest.main()
