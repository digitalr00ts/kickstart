"""Extract a single flat QCOW2 archive without trusting tar paths or links."""

import os
import shutil
import subprocess
import tarfile
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from typing import BinaryIO


def extract_stream(stream: BinaryIO, destination: Path) -> Path:
    """Extract one QCOW2 from a flat tar stream, ignoring allowed package manifests.

    Args:
        stream: Binary tar stream read sequentially without seeking.
        destination: New directory to create for the extracted image.

    Returns:
        Resolved path to the extracted QCOW2 image.

    Raises:
        ValueError: A member is unsafe or unexpected, or the image count is not one.
    """
    destination.mkdir(exist_ok=False)
    image = None
    with tarfile.open(fileobj=stream, mode="r|") as archive:
        for member in archive:
            name = member.name
            if (
                not member.isfile()
                or Path(name).name != name
                or "\\" in name
                or "\n" in name
                or "\r" in name
                or not name.endswith((".qcow2", ".packages"))
            ):
                raise ValueError(f"Unsafe or unexpected archive member: {name!r}")
            if not name.endswith(".qcow2"):
                continue
            if image is not None:
                raise ValueError("Expected exactly one QCOW2 image")
            image = destination / name
            with archive.extractfile(member) as source, image.open("xb") as target:
                shutil.copyfileobj(source, target)
    if image is None:
        raise ValueError("Archive contains no QCOW2 image")
    return image.resolve()


def main() -> None:
    """Decompress the sole artifact archive and append IMAGE_PATH to GITHUB_ENV.

    Raises:
        ValueError: The archive count is not one or decompression fails.
    """
    archives = list(Path("artifacts").glob("*.tar.zst"))
    if len(archives) != 1:
        raise ValueError(f"Expected exactly one archive, found {len(archives)}")
    # Trust runner PATH for zstd; pass the globbed archive after -- as data, without a shell.
    process = subprocess.Popen(  # noqa: S603
        ["zstd", "-dc", "--", str(archives[0])],  # noqa: S607
        stdout=subprocess.PIPE,
    )
    try:
        with process.stdout:
            image = extract_stream(process.stdout, Path("artifacts/extracted"))
        if process.wait() != 0:
            raise ValueError("Archive decompression failed")
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()
    with Path(os.environ["GITHUB_ENV"]).open("a", encoding="utf-8") as env:
        env.write(f"IMAGE_PATH={image}\n")


if __name__ == "__main__":
    main()
