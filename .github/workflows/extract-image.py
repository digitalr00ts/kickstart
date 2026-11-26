"""Extract a single flat QCOW2 archive without trusting tar paths or links."""

import os
import shutil
import subprocess
import tarfile
from pathlib import Path


def extract_stream(stream, destination):
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


def main():
    archives = list(Path("artifacts").glob("*.tar.zst"))
    if len(archives) != 1:
        raise ValueError(f"Expected exactly one archive, found {len(archives)}")
    process = subprocess.Popen(["zstd", "-dc", "--", str(archives[0])], stdout=subprocess.PIPE)
    try:
        with process.stdout:
            image = extract_stream(process.stdout, Path("artifacts/extracted"))
        if process.wait() != 0:
            raise ValueError("Archive decompression failed")
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()
    with open(os.environ["GITHUB_ENV"], "a", encoding="utf-8") as env:
        env.write(f"IMAGE_PATH={image}\n")


if __name__ == "__main__":
    main()
