#!/usr/bin/env python3
"""Disposable native QEMU guest for Molecule; never customize the backing image."""

import argparse
import fcntl
import json
import os
import platform
import shutil
import signal
import socket
import stat
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from collections.abc import Iterable
    from types import FrameType
    from typing import Any, NoReturn

ROOT = Path(__file__).resolve().parents[1]
MIN_SSH_PORT = 1024
MAX_SSH_PORT = 65535


def run(
    argv: Iterable[str | Path],
    **kwargs: Any,  # noqa: ANN401 -- Forward heterogeneous subprocess.run options unchanged.
) -> subprocess.CompletedProcess[bytes | str]:
    """Run caller-built argument lists with checked status and a five-minute timeout."""
    return subprocess.run(  # noqa: S603 -- Internal callers build argv; host tools and environment are trusted.
        [str(x) for x in argv], check=True, timeout=300, **kwargs
    )


def architecture() -> str:
    """Return the supported native architecture using QEMU's naming convention."""
    arch = {"arm64": "aarch64", "amd64": "x86_64"}.get(platform.machine(), platform.machine())
    if arch not in ("x86_64", "aarch64"):
        raise ValueError(f"Unsupported native architecture: {arch}")
    return arch


def ssh_port() -> int:
    """Read the loopback SSH port, rejecting privileged or out-of-range values."""
    value = os.environ.get("VM_SSH_PORT", "2222")
    if not value.isascii() or not value.isdecimal() or not MIN_SSH_PORT <= int(value) <= MAX_SSH_PORT:
        raise ValueError("VM_SSH_PORT must be an integer from 1024 to 65535")
    return int(value)


def image_path(arch: str) -> Path:
    """Resolve one source image and require standalone QCOW2 storage."""
    explicit = os.environ.get("IMAGE_PATH")
    if explicit:
        image = Path(explicit)
        if not image.is_absolute():
            raise ValueError("IMAGE_PATH must be absolute")
    else:
        images = sorted((ROOT / "output" / arch).glob("*.qcow2"))
        if len(images) != 1:
            raise ValueError(f"Expected exactly one output/{arch}/*.qcow2; set absolute IMAGE_PATH")
        image = images[0]
    image = image.resolve(strict=True)
    if not image.is_file():
        raise ValueError("IMAGE_PATH must be a file")
    info = json.loads(run(["qemu-img", "info", "--output=json", image], capture_output=True).stdout)
    if (
        info.get("format") != "qcow2"
        or info.get("backing-filename")
        or info.get("data-file")
        or info.get("format-specific", {}).get("data", {}).get("data-file")
    ):
        raise ValueError("Use a standalone QCOW2 source image")
    return image


def firmware(arch: str, binary: str) -> tuple[Path, Path]:
    """Locate an existing EFI code and variables pair for the native QEMU binary."""
    code, variables = os.environ.get("QEMU_EFI_CODE"), os.environ.get("QEMU_EFI_VARS")
    if code or variables:
        if not code or not variables:
            raise ValueError("Set both QEMU_EFI_CODE and QEMU_EFI_VARS")
        pairs = [(Path(code), Path(variables))]
    elif arch == "x86_64":
        share = Path(binary).resolve().parent.parent / "share" / "qemu"
        pairs = [(share / "edk2-x86_64-code.fd", share / "edk2-i386-vars.fd")]
        pairs += [
            (Path(p) / c, Path(p) / v)
            for p, c, v in [
                ("/usr/share/edk2/ovmf", "OVMF_CODE.fd", "OVMF_VARS.fd"),
                ("/usr/share/OVMF", "OVMF_CODE_4M.fd", "OVMF_VARS_4M.fd"),
                ("/usr/share/OVMF", "OVMF_CODE.fd", "OVMF_VARS.fd"),
            ]
        ]
    else:
        share = Path(binary).resolve().parent.parent / "share" / "qemu"
        pairs = [
            (share / "edk2-aarch64-code.fd", share / "edk2-arm-vars.fd"),
            (
                Path("/usr/share/edk2/aarch64/QEMU_EFI-pflash.raw"),
                Path("/usr/share/edk2/aarch64/vars-template-pflash.raw"),
            ),
            (Path("/usr/share/AAVMF/AAVMF_CODE.fd"), Path("/usr/share/AAVMF/AAVMF_VARS.fd")),
        ]
    for code, variables in pairs:
        if code.is_file() and variables.is_file():
            return code.resolve(), variables.resolve()
    raise ValueError("EFI firmware pair not found; set QEMU_EFI_CODE and QEMU_EFI_VARS")


def qemu_command(state: Path, arch: str, system: str) -> list[str]:
    """Copy writable EFI variables and build argv for the disposable native guest."""
    binary = shutil.which(f"qemu-system-{arch}")
    if not binary:
        raise ValueError(f"Missing qemu-system-{arch}")
    accel = os.environ.get("QEMU_ACCEL", "hvf" if system == "Darwin" else "kvm")
    if accel not in ("tcg", "hvf" if system == "Darwin" else "kvm"):
        raise ValueError("QEMU_ACCEL must be native acceleration or explicit tcg")
    if accel == "kvm" and not os.access("/dev/kvm", os.R_OK | os.W_OK):
        raise ValueError("KVM unavailable; enable /dev/kvm access or explicitly set QEMU_ACCEL=tcg")
    code, variables = firmware(arch, binary)
    shutil.copyfile(variables, state / "efi-vars.fd")
    args = [
        binary,
        "-machine",
        f"{'q35' if arch == 'x86_64' else 'virt'},accel={accel}",
        "-cpu",
        "max" if accel == "tcg" else "host",
        "-m",
        "2048",
        "-smp",
        "2",
        "-display",
        "none",
        "-monitor",
        "none",
        "-serial",
        "stdio",
    ]
    for unit, path, readonly in [(0, code, "on"), (1, state / "efi-vars.fd", "off")]:
        escaped = str(path).replace(",", ",,")
        args += ["-drive", f"if=pflash,unit={unit},format=raw,readonly={readonly},file={escaped}"]
    args += [
        "-blockdev",
        json.dumps(
            {"driver": "qcow2", "node-name": "disk", "file": {"driver": "file", "filename": str(state / "disk.qcow2")}}
        ),
    ]
    return [
        *args,
        "-device",
        "virtio-blk-pci,drive=disk",
        "-netdev",
        f"user,id=net0,restrict=on,hostfwd=tcp:127.0.0.1:{ssh_port()}-:22",
        "-device",
        "virtio-net-pci,netdev=net0",
    ]


def customize(state: Path, image: Path, system: str) -> None:
    """Create an overlay and inject test-only access without modifying the source."""
    run(["qemu-img", "create", "-f", "qcow2", "-F", "qcow2", "-b", image, state / "disk.qcow2"])
    run(["ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-f", state / "id_ed25519"])
    (state / "sudoers").write_text("admin ALL=(ALL) NOPASSWD: ALL\n")
    # Replace build-time authentication only in the disposable overlay, offline.
    (state / "sshd.conf").write_text(
        "PasswordAuthentication no\nKbdInteractiveAuthentication no\nPermitRootLogin no\nPubkeyAuthentication yes\n"
    )
    args = [
        "virt-customize",
        "--format",
        "qcow2",
        "-a",
        str(state / "disk.qcow2"),
        "--no-network",
        "--run-command",
        (
            "passwd -l admin && "
            "rm -f /root/.ssh/authorized_keys /home/admin/.ssh/authorized_keys && "
            "install -d -m 0755 /etc/sudoers.d /etc/ssh/sshd_config.d"
        ),
        "--ssh-inject",
        f"admin:file:{state / 'id_ed25519.pub'}",
        "--upload",
        f"{state / 'sudoers'}:/etc/sudoers.d/99-molecule",
        "--chmod",
        "0440:/etc/sudoers.d/99-molecule",
        "--chown",
        "0:0:/etc/sudoers.d/99-molecule",
        "--upload",
        f"{state / 'sshd.conf'}:/etc/ssh/sshd_config.d/00-molecule.conf",
        "--chown",
        "0:0:/etc/ssh/sshd_config.d/00-molecule.conf",
        "--selinux-relabel",
    ]
    if system == "Darwin":
        if not image.is_relative_to(Path.home().resolve()):
            raise ValueError("macOS IMAGE_PATH must be under home, shared with kiwi-builder")
        args = [
            "limactl",
            "shell",
            os.environ.get("LIMA_INSTANCE", "kiwi-builder"),
            "sudo",
            "env",
            "LIBGUESTFS_BACKEND=direct",
            *args,
        ]
    run(args, env={**os.environ, "LIBGUESTFS_BACKEND": "direct"})


def rpc(state: Path, action: str) -> dict[str, bool | str]:
    """Send a supervisor action over its private socket and require an OK reply."""
    with socket.socket(socket.AF_UNIX) as client:
        client.settimeout(20)
        client.connect(str(state / "control.sock"))
        client.sendall((action + "\n").encode())
        data = b""
        while not data.endswith(b"\n"):
            chunk = client.recv(4096)
            if not chunk:
                raise RuntimeError("Supervisor disconnected; preserve state for recovery")
            data += chunk
        reply = json.loads(data)
        if not reply.get("ok"):
            raise RuntimeError(reply.get("error", "Guest is not running"))
        return reply


def stop_child(child: subprocess.Popen[bytes]) -> None:
    """Terminate and reap the owned child, escalating to kill after ten seconds."""
    # A retained Popen child cannot have its PID reused before wait/reaping.
    if child.poll() is None:
        child.terminate()
        try:
            child.wait(timeout=10)
        except subprocess.TimeoutExpired:
            child.kill()
            child.wait(timeout=10)


def supervise(state: Path) -> None:
    """Own the QEMU child and acknowledge stop only after it has been reaped."""
    child = None

    def interrupted(signum: int, _frame: FrameType | None) -> NoReturn:
        """Exit through the supervisor's child-cleanup boundary on a signal."""
        raise SystemExit(128 + signum)

    signal.signal(signal.SIGTERM, interrupted)
    signal.signal(signal.SIGINT, interrupted)
    try:
        with socket.socket(socket.AF_UNIX) as server, (state / "console.log").open("ab") as log:
            server.bind(str(state / "control.sock"))
            server.listen(2)
            command = json.loads((state / "command.json").read_text())
            child = subprocess.Popen(  # noqa: S603 -- Parent-generated argv is stored in owner-only runtime state.
                command, stdin=subprocess.DEVNULL, stdout=log, stderr=log
            )
            while True:
                connection, _ = server.accept()
                with connection:
                    connection.settimeout(5)
                    action = connection.recv(32).decode().strip()
                    if action == "stop":
                        stop_child(child)
                        connection.sendall(b'{"ok":true}\n')
                        return
                    reply = {"ok": action == "status" and child.poll() is None}
                    connection.sendall((json.dumps(reply) + "\n").encode())
    finally:
        if child is not None:
            stop_child(child)


def connection_config(state: Path, port: int) -> list[dict[str, str | int]]:
    """Build Molecule connection data for loopback SSH with the transient key."""
    return [
        {
            "instance": "instance",
            "address": "127.0.0.1",
            "user": "admin",
            "port": port,
            "identity_file": str(state / "id_ed25519"),
        }
    ]


def wait_for_ssh(state: Path, port: int) -> None:
    """Require a live supervisor and SSH admin/sudo readiness within 240 seconds."""
    command = [
        "ssh",
        "-F",
        "/dev/null",
        "-p",
        str(port),
        "-i",
        str(state / "id_ed25519"),
        "-o",
        "BatchMode=yes",
        "-o",
        "IdentitiesOnly=yes",
        "-o",
        "StrictHostKeyChecking=no",
        "-o",
        "UserKnownHostsFile=/dev/null",
        "-o",
        "ConnectTimeout=3",
        "admin@127.0.0.1",
        'test "$(id -un)" = admin && sudo -n true',
    ]
    deadline = time.monotonic() + 240
    while time.monotonic() < deadline:
        rpc(state, "status")
        try:
            result = subprocess.run(  # noqa: S603 -- Fixed SSH probe targets loopback using the private test key.
                command, check=False, timeout=8, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
            )
            if result.returncode == 0:
                return
        except subprocess.TimeoutExpired:
            pass
        time.sleep(2)
    raise RuntimeError(f"Guest SSH/admin/sudo readiness timed out; inspect {state / 'console.log'}")


def checked_state(pointer: Path) -> Path:
    """Require the pointer to name an owner-only runtime directory under home."""
    state = Path(pointer.read_text().strip())
    info = state.lstat()
    if (
        state.parent != Path.home().resolve()
        or not state.name.startswith(".molecule-vm-")
        or not stat.S_ISDIR(info.st_mode)
        or info.st_uid != os.getuid()
        or info.st_mode & 0o077
    ):
        raise ValueError("Refusing unsafe VM state directory")
    return state


def archive_logs(state: Path) -> None:
    """Copy only regular, non-symlink guest logs to VM_LOG_DIR when configured."""
    destination = os.environ.get("VM_LOG_DIR")
    if destination:
        directory = Path(destination)
        directory.mkdir(mode=0o700, parents=True, exist_ok=True)
        for name in ("console.log", "supervisor.log"):
            source = state / name
            if source.is_file() and not source.is_symlink():
                shutil.copyfile(source, directory / name)


def destroy(pointer: Path, config: Path) -> None:
    """Archive logs and remove private state only after supervisor-confirmed stop."""
    if pointer.exists():
        state = checked_state(pointer)
        # Never signal a saved PID or delete a disk until its owning supervisor acknowledges exit.
        try:
            rpc(state, "stop")
        finally:
            archive_logs(state)
        shutil.rmtree(state)
        pointer.unlink()
    config.write_text("[]\n")


def start(pointer: Path, config: Path) -> None:
    """Reuse a ready guest or launch one, retaining state if shutdown is unconfirmed."""
    if pointer.exists():
        state = checked_state(pointer)
        rpc(state, "status")
        port = json.loads((state / "instance.json").read_text())[0]["port"]
        wait_for_ssh(state, port)
        config.write_text((state / "instance.json").read_text())
        return
    system, arch, port = platform.system(), architecture(), ssh_port()
    if system not in ("Linux", "Darwin"):
        raise ValueError("Only Linux and macOS hosts are supported")
    image = image_path(arch)
    with socket.socket() as probe:
        probe.bind(("127.0.0.1", port))
    state = Path(tempfile.mkdtemp(prefix=".molecule-vm-", dir=Path.home().resolve()))
    worker = None
    launch_attempted = False
    try:
        command = qemu_command(state, arch, system)
        customize(state, image, system)
        (state / "command.json").write_text(json.dumps(command))
        (state / "instance.json").write_text(json.dumps(connection_config(state, port)))
        pointer.write_text(str(state))
        with (state / "supervisor.log").open("ab") as log:
            launch_attempted = True
            worker = subprocess.Popen(  # noqa: S603 -- Relaunch this script with the current interpreter and private state.
                [sys.executable, str(Path(__file__).resolve()), "_supervise", str(state)],
                stdin=subprocess.DEVNULL,
                stdout=log,
                stderr=log,
                start_new_session=True,
            )
        for _ in range(100):
            if worker.poll() is not None:
                # Keep startup failure inside the boundary that stops the guest or retains its state.
                raise RuntimeError(f"Supervisor failed; inspect {state / 'supervisor.log'}")  # noqa: TRY301
            try:
                rpc(state, "status")
                break
            except FileNotFoundError, ConnectionRefusedError:
                time.sleep(0.1)
        else:
            # Keep timeout inside the boundary that stops the guest or retains its state.
            raise RuntimeError("Supervisor startup timed out")  # noqa: TRY301
        wait_for_ssh(state, port)
        config.write_text((state / "instance.json").read_text())
    except BaseException:
        if not launch_attempted:
            shutil.rmtree(state)
            pointer.unlink(missing_ok=True)
        else:
            for name in ("console.log", "supervisor.log"):
                log = state / name
                if log.exists():
                    print(f"{name}:\n{log.read_bytes()[-8000:].decode(errors='replace')}", file=sys.stderr)
            # Failed cleanup intentionally retains state; do not risk deleting a live overlay.
            try:
                destroy(pointer, config)
            except OSError, RuntimeError:
                print(f"Cleanup unconfirmed; retained private state: {state}", file=sys.stderr)
        raise


def main() -> None:
    """Dispatch lifecycle actions, locking Molecule state for start and destroy."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["start", "destroy", "_supervise"])
    parser.add_argument("state", nargs="?")
    args = parser.parse_args()
    os.umask(0o077)
    if args.action == "_supervise":
        supervise(Path(args.state))
        return
    ephemeral = Path(os.environ["MOLECULE_EPHEMERAL_DIRECTORY"]).resolve()
    config = Path(os.environ["MOLECULE_INSTANCE_CONFIG"])
    ephemeral.mkdir(parents=True, exist_ok=True)
    with (ephemeral / "vm.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        pointer = ephemeral / "vm-state"
        (start if args.action == "start" else destroy)(pointer, config)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError, KeyError) as exc:
        sys.exit(str(exc))
