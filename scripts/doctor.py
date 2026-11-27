"""Check host prerequisites without installing tools, starting guests or modifying files."""

import argparse
import importlib.util
import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load_helpers():
    # Importing normally can create __pycache__, violating the read-only contract.
    previous = sys.dont_write_bytecode
    sys.dont_write_bytecode = True
    try:
        spec = importlib.util.spec_from_file_location("doctor_vm_test", ROOT / "scripts/vm-test.py")
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module
    finally:
        sys.dont_write_bytecode = previous


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scope", choices=("build", "test", "all"), default="all")
    args = parser.parse_args(argv)
    results = []

    def check(ok, message):
        results.append(bool(ok))
        print(f"{'PASS' if ok else 'FAIL'}: {message}")

    system = platform.system()
    supported = system in ("Linux", "Darwin")
    check(supported, f"Host OS: {system}; use Linux or macOS (Darwin)")
    vm, arch = None, None
    if supported:
        try:
            vm = load_helpers()
            arch = vm.architecture()
            check(True, f"Native architecture: {arch}")
        except (OSError, ValueError, ImportError) as exc:
            check(False, f"Native architecture/helpers: {exc}; use x86_64 or aarch64")

    tools = {"uv": "Install uv; see docs/building.md#prerequisites"}
    if supported and args.scope in ("build", "all"):
        if system == "Linux":
            # Indicative essentials for the current Btrfs/EFI QCOW2 description, not systemdeps validation.
            for tool in (
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
            ):
                tools[tool] = "Install kiwi-systemdeps (Fedora) or equivalent host disk/filesystem tools"
            if os.geteuid() != 0:
                tools["sudo"] = "Install/configure sudo for privileged KIWI operations; no sudo probe is run"
        else:
            tools["limactl"] = "Install Lima: brew install lima"
            try:
                check(
                    ROOT.resolve().is_relative_to(Path.home().resolve()),
                    "Keep the checkout under home for Lima's writable home share",
                )
            except (OSError, RuntimeError) as exc:
                check(False, f"Cannot resolve checkout/home: {exc}; check path permissions/symlinks")

    testing = supported and args.scope in ("test", "all")
    if testing:
        for tool in ("qemu-img", "ssh", "ssh-keygen"):
            tools[tool] = "Install QEMU and OpenSSH clients; see docs/building.md#prerequisites"
        if arch:
            tools[f"qemu-system-{arch}"] = "Install native QEMU; see docs/building.md#prerequisites"
        tool = "virt-customize" if system == "Linux" else "limactl"
        tools[tool] = "Install libguestfs-tools-c (Linux) or Lima (macOS); see docs/testing.md"
        if system == "Darwin" and "IMAGE_PATH" in os.environ:
            try:
                image = Path(os.environ["IMAGE_PATH"])
                check(
                    image.is_absolute() and image.resolve().is_relative_to(Path.home().resolve()),
                    "IMAGE_PATH must be absolute and under home for Lima (existence not required)",
                )
            except (OSError, RuntimeError) as exc:
                check(False, f"Cannot resolve IMAGE_PATH/home: {exc}; check path permissions/symlinks")

    binaries = {}
    for tool, remedy in tools.items():
        binaries[tool] = shutil.which(tool)
        check(binaries[tool], f"{tool}: {binaries[tool] or remedy}")

    if testing:
        native = "kvm" if system == "Linux" else "hvf"
        accel = os.environ.get("QEMU_ACCEL", native)
        check(accel in (native, "tcg"), f"QEMU_ACCEL={accel!r}; choose {native} or explicit tcg")
        if accel == "kvm" and system == "Linux":
            check(
                os.access("/dev/kvm", os.R_OK | os.W_OK),
                "KVM read/write access: enable /dev/kvm access or set QEMU_ACCEL=tcg",
            )
        binary = binaries.get(f"qemu-system-{arch}")
        if binary:
            try:
                code, variables = vm.firmware(arch, binary)
                check(True, f"EFI pair lookup for {arch}: {code}, {variables}")
            except (OSError, ValueError, RuntimeError) as exc:
                check(
                    False,
                    f"EFI: {exc}; install matching firmware or set both "
                    "QEMU_EFI_CODE and QEMU_EFI_VARS (docs/testing.md)",
                )
            if system == "Darwin" and accel == "hvf":
                try:
                    result = subprocess.run(
                        [binary, "-accel", "help"],
                        check=True,
                        timeout=5,
                        stdin=subprocess.DEVNULL,
                        capture_output=True,
                        text=True,
                    )
                    check(
                        "hvf" in result.stdout.split(),
                        "QEMU lists hvf (not proof it is usable); if absent install HVF-capable QEMU "
                        "or explicitly set QEMU_ACCEL=tcg",
                    )
                except (OSError, subprocess.SubprocessError) as exc:
                    check(
                        False,
                        f"Cannot query QEMU accelerators: {exc}; check QEMU installation "
                        "or explicitly set QEMU_ACCEL=tcg",
                    )
        else:
            check(False, "EFI lookup unavailable; install native QEMU and use a supported architecture")

    failures = results.count(False)
    print(f"Summary: {len(results) - failures} passed, {failures} failed ({args.scope})")
    print(
        "Limitations: indicative executable/path checks only; no proof KIWI systemdeps are complete, "
        "EFI files match in content, Lima guest readiness, or actual acceleration/boot. "
        "No built image is required or inspected. See docs/building.md and docs/testing.md."
    )
    return int(bool(failures))


if __name__ == "__main__":
    sys.exit(main())
