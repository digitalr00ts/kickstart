"""Regression tests for the VM runner; no QEMU, Lima or SSH processes are started."""

import importlib.util
import io
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

SPEC = importlib.util.spec_from_file_location("vm_test", Path(__file__).resolve().parents[1] / "scripts/vm-test.py")
vm = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(vm)


class RunnerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.env = patch.dict(os.environ, {}, clear=True)
        self.env.start()
        self.addCleanup(self.env.stop)
        home_patch = patch.object(Path, "home", return_value=self.home)
        home_patch.start()
        self.addCleanup(home_patch.stop)
        self.state = self.home / ".molecule-vm-test"
        self.state.mkdir(mode=0o700)
        self.pointer = self.home / "vm-state"
        self.config = self.home / "instance-config.yml"

    def test_native_architecture_aliases_and_rejection(self):
        for raw, expected in [("arm64", "aarch64"), ("aarch64", "aarch64"), ("amd64", "x86_64"), ("x86_64", "x86_64")]:
            with self.subTest(raw=raw), patch.object(vm.platform, "machine", return_value=raw):
                self.assertEqual(vm.architecture(), expected)
        with patch.object(vm.platform, "machine", return_value="riscv64"), self.assertRaises(ValueError):
            vm.architecture()

    def test_default_port_and_validation(self):
        self.assertEqual(vm.ssh_port(), 2222)
        for value in ["", "0", "22", "65536", "abc", "22.5", "２２２２", "-1"]:
            with (
                self.subTest(value=value),
                patch.dict(os.environ, {"VM_SSH_PORT": value}),
                self.assertRaises(ValueError),
            ):
                vm.ssh_port()
        with patch.dict(os.environ, {"VM_SSH_PORT": "65535"}):
            self.assertEqual(vm.ssh_port(), 65535)

    def test_image_selection_requires_exactly_one_native_artifact(self):
        output = self.home / "output/aarch64"
        output.mkdir(parents=True)
        with patch.object(vm, "ROOT", self.home), patch.object(vm, "run") as run:
            run.return_value.stdout = b'{"format":"qcow2"}'
            with self.assertRaisesRegex(ValueError, "exactly one"):
                vm.image_path("aarch64")
            image = output / "fedora.qcow2"
            image.touch()
            self.assertEqual(vm.image_path("aarch64"), image)
            (output / "other.qcow2").touch()
            with self.assertRaisesRegex(ValueError, "exactly one"):
                vm.image_path("aarch64")

    def test_explicit_image_must_be_absolute_standalone_qcow2(self):
        with patch.dict(os.environ, {"IMAGE_PATH": "relative.qcow2"}), self.assertRaises(ValueError):
            vm.image_path("x86_64")
        image = self.home / "source.qcow2"
        image.touch()
        with patch.dict(os.environ, {"IMAGE_PATH": str(image)}), patch.object(vm, "run") as run:
            run.return_value.stdout = b'{"format":"qcow2"}'
            self.assertEqual(vm.image_path("aarch64"), image)
            for info in [
                {"format": "raw"},
                {"format": "qcow2", "backing-filename": "base"},
                {"format": "qcow2", "data-file": "external"},
                {"format": "qcow2", "format-specific": {"data": {"data-file": "external"}}},
            ]:
                run.return_value.stdout = json.dumps(info)
                with self.assertRaises(ValueError):
                    vm.image_path("aarch64")

    def test_firmware_override_requires_both_existing_files(self):
        with patch.dict(os.environ, {"QEMU_EFI_CODE": "/missing"}), self.assertRaises(ValueError):
            vm.firmware("x86_64", "/bin/qemu")
        code, variables = self.home / "code.fd", self.home / "vars.fd"
        code.touch()
        variables.touch()
        with patch.dict(os.environ, {"QEMU_EFI_CODE": str(code), "QEMU_EFI_VARS": str(variables)}):
            self.assertEqual(vm.firmware("aarch64", "/bin/qemu"), (code, variables))

    def test_qemu_platform_matrix_uses_overlay_efi_and_loopback(self):
        code, variables = self.home / "code.fd", self.home / "vars.fd"
        code.touch()
        variables.write_bytes(b"nvram")
        for system, accel in [("Linux", "kvm"), ("Darwin", "hvf")]:
            for arch, machine in [("x86_64", "q35"), ("aarch64", "virt")]:
                with (
                    self.subTest(system=system, arch=arch),
                    patch.object(vm.shutil, "which", return_value="/bin/qemu"),
                    patch.object(vm, "firmware", return_value=(code, variables)),
                    patch.object(vm.os, "access", return_value=True),
                ):
                    args = vm.qemu_command(self.state, arch, system)
                    self.assertIn(f"{machine},accel={accel}", args)
                    self.assertIn(f"if=pflash,unit=0,format=raw,readonly=on,file={code}", args)
                    self.assertIn(f"if=pflash,unit=1,format=raw,readonly=off,file={self.state / 'efi-vars.fd'}", args)
                    self.assertIn("user,id=net0,restrict=on,hostfwd=tcp:127.0.0.1:2222-:22", args)
                    devices = [json.loads(args[i + 1]) for i, arg in enumerate(args) if arg == "-blockdev"]
                    self.assertEqual(devices[0]["file"]["filename"], str(self.state / "disk.qcow2"))
                    self.assertEqual((self.state / "efi-vars.fd").read_bytes(), b"nvram")
                    self.assertNotIn("-daemonize", args)
                    self.assertNotIn("-pidfile", args)

    def test_kvm_requires_access_and_tcg_is_explicit(self):
        with (
            patch.object(vm.shutil, "which", return_value="/bin/qemu"),
            patch.object(vm.os, "access", return_value=False),
        ):
            with self.assertRaisesRegex(ValueError, "KVM unavailable"):
                vm.qemu_command(self.state, "aarch64", "Linux")
            with patch.dict(os.environ, {"QEMU_ACCEL": "hvf"}), self.assertRaises(ValueError):
                vm.qemu_command(self.state, "aarch64", "Linux")
            variables = self.home / "vars.fd"
            variables.touch()
            with (
                patch.dict(os.environ, {"QEMU_ACCEL": "tcg"}),
                patch.object(vm, "firmware", return_value=(variables, variables)),
            ):
                args = vm.qemu_command(self.state, "aarch64", "Linux")
                self.assertIn("virt,accel=tcg", args)
                self.assertIn("max", args)

    def test_customization_only_writes_overlay_and_injects_ephemeral_auth_offline(self):
        image = self.home / "source.qcow2"
        image.write_bytes(b"source unchanged")
        with patch.object(vm, "run") as run:
            vm.customize(self.state, image, "Linux")
        commands = [call.args[0] for call in run.call_args_list]
        self.assertEqual(
            commands[0], ["qemu-img", "create", "-f", "qcow2", "-F", "qcow2", "-b", image, self.state / "disk.qcow2"]
        )
        self.assertIn("ed25519", commands[1])
        custom = commands[2]
        self.assertEqual(custom[custom.index("-a") + 1], str(self.state / "disk.qcow2"))
        self.assertIn("--no-network", custom)
        self.assertIn("--selinux-relabel", custom)
        self.assertIn("0:0:/etc/sudoers.d/99-molecule", custom)
        self.assertIn("0:0:/etc/ssh/sshd_config.d/00-molecule.conf", custom)
        self.assertLess(custom.index("--run-command"), custom.index("--ssh-inject"))
        self.assertIn("admin:file:", custom[custom.index("--ssh-inject") + 1])
        self.assertIn("passwd -l admin", custom[custom.index("--run-command") + 1])
        self.assertEqual((self.state / "sudoers").read_text(), "admin ALL=(ALL) NOPASSWD: ALL\n")
        self.assertIn("PasswordAuthentication no", (self.state / "sshd.conf").read_text())
        self.assertEqual(image.read_bytes(), b"source unchanged")

    def test_macos_customizes_in_existing_builder_and_requires_shared_image(self):
        with patch.object(vm, "run") as run:
            vm.customize(self.state, self.home / "source.qcow2", "Darwin")
            args = run.call_args.args[0]
            self.assertEqual(
                args[:7],
                ["limactl", "shell", "kiwi-builder", "sudo", "env", "LIBGUESTFS_BACKEND=direct", "virt-customize"],
            )
            self.assertNotIn("start", args)
            self.assertNotIn("create", args)
            with self.assertRaisesRegex(ValueError, "under home"):
                vm.customize(self.state, Path("/not-shared/source.qcow2"), "Darwin")

    def test_macos_customization_honors_selected_builder(self):
        with patch.dict(os.environ, {"LIMA_INSTANCE": "custom-builder"}), patch.object(vm, "run") as run:
            vm.customize(self.state, self.home / "source.qcow2", "Darwin")
            self.assertEqual(run.call_args.args[0][:3], ["limactl", "shell", "custom-builder"])

    def test_connection_config_is_admin_with_temporary_key(self):
        config = vm.connection_config(self.state, 2222)[0]
        self.assertEqual(config["instance"], "instance")
        self.assertEqual(config["user"], "admin")
        self.assertEqual(config["address"], "127.0.0.1")
        self.assertEqual(config["port"], 2222)
        self.assertEqual(config["identity_file"], str(self.state / "id_ed25519"))
        self.assertNotIn("password", config)

    def test_destroy_waits_for_supervisor_before_deleting_and_is_idempotent(self):
        self.pointer.write_text(str(self.state))
        with patch.object(vm, "rpc") as rpc:
            rpc.side_effect = lambda state, action: self.assertTrue(state.exists())
            vm.destroy(self.pointer, self.config)
            rpc.assert_called_once_with(self.state, "stop")
        self.assertFalse(self.state.exists())
        self.assertFalse(self.pointer.exists())
        self.assertEqual(json.loads(self.config.read_text()), [])
        vm.destroy(self.pointer, self.config)

    def test_destroy_archives_only_logs_after_shutdown(self):
        destination = self.home / "logs"
        os.environ["VM_LOG_DIR"] = str(destination)
        self.pointer.write_text(str(self.state))
        for name in ("console.log", "supervisor.log", "id_ed25519", "disk.qcow2"):
            (self.state / name).write_text(name)
        with patch.object(vm, "rpc") as rpc:
            rpc.side_effect = lambda *_: (self.state / "console.log").write_text("final console")
            vm.destroy(self.pointer, self.config)
        self.assertEqual(sorted(path.name for path in destination.iterdir()), ["console.log", "supervisor.log"])
        self.assertEqual((destination / "console.log").read_text(), "final console")
        self.assertFalse(self.state.exists())

    def test_unconfirmed_shutdown_still_archives_logs_and_retains_state(self):
        destination = self.home / "logs"
        os.environ["VM_LOG_DIR"] = str(destination)
        self.pointer.write_text(str(self.state))
        (self.state / "console.log").write_text("boot failure")
        (self.state / "supervisor.log").symlink_to(self.home / "secret")
        (self.home / "secret").write_text("not a log")
        with patch.object(vm, "rpc", side_effect=ConnectionRefusedError), self.assertRaises(ConnectionRefusedError):
            vm.destroy(self.pointer, self.config)
        self.assertEqual((destination / "console.log").read_text(), "boot failure")
        self.assertFalse((destination / "supervisor.log").exists())
        self.assertTrue(self.state.exists())
        self.assertTrue(self.pointer.exists())

    def test_log_archive_failure_preserves_state_after_stopping(self):
        os.environ["VM_LOG_DIR"] = str(self.home / "logs")
        self.pointer.write_text(str(self.state))
        (self.state / "console.log").touch()
        with (
            patch.object(vm, "rpc") as rpc,
            patch.object(vm.shutil, "copyfile", side_effect=OSError),
            self.assertRaises(OSError),
        ):
            vm.destroy(self.pointer, self.config)
        rpc.assert_called_once_with(self.state, "stop")
        self.assertTrue(self.state.exists())
        self.assertTrue(self.pointer.exists())

    def test_unconfirmed_shutdown_keeps_overlay_keys_and_pointer(self):
        self.pointer.write_text(str(self.state))
        (self.state / "disk.qcow2").touch()
        with patch.object(vm, "rpc", side_effect=ConnectionRefusedError), self.assertRaises(ConnectionRefusedError):
            vm.destroy(self.pointer, self.config)
        self.assertTrue((self.state / "disk.qcow2").exists())
        self.assertTrue(self.pointer.exists())

    def test_unsafe_state_and_symlink_are_rejected(self):
        self.pointer.write_text(str(self.home))
        with self.assertRaises(ValueError):
            vm.checked_state(self.pointer)
        link = self.home / ".molecule-vm-link"
        link.symlink_to(self.state, target_is_directory=True)
        self.pointer.write_text(str(link))
        with self.assertRaises(ValueError):
            vm.checked_state(self.pointer)
        self.state.chmod(0o755)
        self.pointer.write_text(str(self.state))
        with self.assertRaises(ValueError):
            vm.checked_state(self.pointer)

    def test_stop_uses_retained_child_and_waits_before_escalation(self):
        child = MagicMock()
        child.poll.return_value = None
        child.wait.side_effect = [subprocess.TimeoutExpired("qemu", 10), 0]
        vm.stop_child(child)
        child.terminate.assert_called_once()
        child.kill.assert_called_once()
        self.assertEqual(child.wait.call_count, 2)
        child.reset_mock()
        child.poll.return_value = 0
        vm.stop_child(child)
        child.terminate.assert_not_called()
        child.kill.assert_not_called()

    def test_supervisor_acknowledges_only_after_child_exit(self):
        (self.state / "command.json").write_text('["qemu", "overlay-only"]')
        server, connection, child = MagicMock(), MagicMock(), MagicMock()
        server.accept.return_value = (connection, None)
        connection.__enter__.return_value = connection
        connection.recv.return_value = b"stop\n"
        child.poll.return_value = None
        connection.sendall.side_effect = lambda data: child.wait.assert_called()
        with (
            patch.object(vm.signal, "signal"),
            patch.object(vm.socket, "socket") as sock,
            patch.object(vm.subprocess, "Popen", return_value=child) as popen,
        ):
            sock.return_value.__enter__.return_value = server
            vm.supervise(self.state)
        self.assertEqual(popen.call_args.args[0], ["qemu", "overlay-only"])
        child.terminate.assert_called()
        connection.sendall.assert_called_once_with(b'{"ok":true}\n')

    def test_ssh_retries_and_checks_admin_sudo(self):
        with patch.object(vm, "rpc"), patch.object(vm.time, "sleep"), patch.object(vm.subprocess, "run") as run:
            run.side_effect = [subprocess.TimeoutExpired("ssh", 8), MagicMock(returncode=1), MagicMock(returncode=0)]
            vm.wait_for_ssh(self.state, 2222)
            self.assertEqual(run.call_count, 3)
            args = run.call_args.args[0]
            self.assertIn("admin@127.0.0.1", args)
            self.assertIn("sudo -n true", args[-1])
            self.assertIn("IdentitiesOnly=yes", args)

    def test_ssh_timeout_is_actionable(self):
        with (
            patch.object(vm.time, "monotonic", side_effect=[0, 241]),
            self.assertRaisesRegex(RuntimeError, "console.log"),
        ):
            vm.wait_for_ssh(self.state, 2222)

    def test_start_reuses_live_scenario_not_second_guest(self):
        self.pointer.write_text(str(self.state))
        data = json.dumps(vm.connection_config(self.state, 3333))
        (self.state / "instance.json").write_text(data)
        with (
            patch.object(vm, "rpc"),
            patch.object(vm, "wait_for_ssh") as wait,
            patch.object(vm.subprocess, "Popen") as popen,
        ):
            vm.start(self.pointer, self.config)
        popen.assert_not_called()
        wait.assert_called_once_with(self.state, 3333)
        self.assertEqual(self.config.read_text(), data)

    def test_start_failure_before_launch_removes_private_state(self):
        with (
            patch.object(vm.platform, "system", return_value="Linux"),
            patch.object(vm, "architecture", return_value="aarch64"),
            patch.object(vm, "image_path", return_value=self.home / "image.qcow2"),
            patch.object(vm.socket, "socket"),
            patch.object(vm, "qemu_command", return_value=["qemu"]),
            patch.object(vm, "customize", side_effect=RuntimeError("customize failed")),
            self.assertRaisesRegex(RuntimeError, "customize failed"),
        ):
            vm.start(self.pointer, self.config)
        self.assertEqual(list(self.home.glob(".molecule-vm-*")), [self.state])
        self.assertFalse(self.pointer.exists())

    def prepare_start(self):
        for target, name, value in [
            (vm.platform, "system", "Linux"),
            (vm, "architecture", "aarch64"),
            (vm, "image_path", self.home / "source.qcow2"),
            (vm, "qemu_command", ["qemu", "private-overlay"]),
        ]:
            self.enterContext(patch.object(target, name, return_value=value))
        self.enterContext(patch.object(vm.socket, "socket"))
        self.enterContext(patch.object(vm, "customize"))
        popen = self.enterContext(patch.object(vm.subprocess, "Popen"))
        popen.return_value.poll.return_value = None
        rpc = self.enterContext(patch.object(vm, "rpc", return_value={"ok": True}))
        wait = self.enterContext(patch.object(vm, "wait_for_ssh"))
        self.enterContext(patch.object(vm.sys, "stderr", io.StringIO()))
        return popen, rpc, wait

    def test_start_publishes_config_only_after_readiness(self):
        popen, rpc, wait = self.prepare_start()
        wait.side_effect = lambda state, port: self.assertFalse(self.config.exists())
        vm.start(self.pointer, self.config)
        state = vm.checked_state(self.pointer)
        self.assertEqual(state.stat().st_mode & 0o777, 0o700)
        self.assertEqual(json.loads(self.config.read_text()), vm.connection_config(state, 2222))
        self.assertTrue(popen.call_args.kwargs["start_new_session"])
        self.assertEqual(popen.call_args.args[0][-2:], ["_supervise", str(state)])
        rpc.assert_called_once_with(state, "status")
        vm.destroy(self.pointer, self.config)

    def test_failed_readiness_stops_owned_guest_and_removes_secrets(self):
        _, rpc, wait = self.prepare_start()
        wait.side_effect = RuntimeError("SSH failed")
        with self.assertRaisesRegex(RuntimeError, "SSH failed"):
            vm.start(self.pointer, self.config)
        self.assertEqual(rpc.call_args.args[1], "stop")
        self.assertFalse(self.pointer.exists())
        self.assertEqual(list(self.home.glob(".molecule-vm-*")), [self.state])
        self.assertEqual(json.loads(self.config.read_text()), [])

    def test_ambiguous_spawn_failure_preserves_potential_live_disk(self):
        popen, rpc, _ = self.prepare_start()
        popen.side_effect = OSError("spawn interrupted")
        rpc.side_effect = ConnectionRefusedError
        with self.assertRaisesRegex(OSError, "spawn interrupted"):
            vm.start(self.pointer, self.config)
        self.assertTrue(vm.checked_state(self.pointer).exists())
        self.assertFalse(self.config.exists())

    def test_rpc_requires_positive_acknowledgement(self):
        with patch.object(vm.socket, "socket") as sock:
            client = sock.return_value.__enter__.return_value
            client.recv.return_value = b'{"ok":true}\n'
            self.assertEqual(vm.rpc(self.state, "stop"), {"ok": True})
            client.sendall.assert_called_once_with(b"stop\n")
            client.recv.return_value = b'{"ok":false}\n'
            with self.assertRaises(RuntimeError):
                vm.rpc(self.state, "status")
            client.recv.return_value = b""
            with self.assertRaisesRegex(RuntimeError, "disconnected"):
                vm.rpc(self.state, "stop")


if __name__ == "__main__":
    unittest.main()
