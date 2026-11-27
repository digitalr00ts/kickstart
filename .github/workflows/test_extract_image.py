"""Exercise archive validation without downloading images or starting QEMU."""

import importlib.util
import io
import tarfile
import tempfile
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location("extract_image", Path(__file__).with_name("extract-image.py"))
extract_image = importlib.util.module_from_spec(spec)
spec.loader.exec_module(extract_image)


class ArchiveTests(unittest.TestCase):
    def extract(self, members):
        stream = io.BytesIO()
        with tarfile.open(fileobj=stream, mode="w") as archive:
            for name, kind in members:
                member = tarfile.TarInfo(name)
                member.type = kind
                if kind == tarfile.REGTYPE:
                    member.size = 4
                    archive.addfile(member, io.BytesIO(b"test"))
                else:
                    member.linkname = "/tmp/target"  # noqa: S108 -- Malicious archive metadata, never a host file.
                    archive.addfile(member)
        stream.seek(0)
        with tempfile.TemporaryDirectory() as directory:
            image = extract_image.extract_stream(stream, Path(directory) / "extracted")
            return image.name, image.read_bytes()

    def test_image_with_optional_manifest(self):
        self.assertEqual(
            self.extract([("image.qcow2", tarfile.REGTYPE), ("image.packages", tarfile.REGTYPE)]),
            ("image.qcow2", b"test"),
        )

    def test_reject_unsafe_names_and_types(self):
        for name, kind in [
            ("../image.qcow2", tarfile.REGTYPE),
            ("/image.qcow2", tarfile.REGTYPE),
            ("dir/image.qcow2", tarfile.REGTYPE),
            ("dir\\image.qcow2", tarfile.REGTYPE),
            ("image\nINJECT=value.qcow2", tarfile.REGTYPE),
            ("image.qcow2", tarfile.SYMTYPE),
            ("image.qcow2", tarfile.LNKTYPE),
            ("image.qcow2", tarfile.CHRTYPE),
            ("unexpected.sh", tarfile.REGTYPE),
        ]:
            with self.subTest(name=name, kind=kind), self.assertRaises(ValueError):
                self.extract([(name, kind)])

    def test_reject_multiple_images(self):
        with self.assertRaisesRegex(ValueError, "exactly one"):
            self.extract([("one.qcow2", tarfile.REGTYPE), ("two.qcow2", tarfile.REGTYPE)])

    def test_reject_missing_image(self):
        with self.assertRaisesRegex(ValueError, "no QCOW2"):
            self.extract([("image.packages", tarfile.REGTYPE)])


if __name__ == "__main__":
    unittest.main()
