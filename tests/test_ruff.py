"""Exercise Ruff's resolved policy without writing fixtures or starting guests."""

import json
import shutil
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUFF = shutil.which("ruff")


@unittest.skipUnless(RUFF, "mise-managed Ruff executable is not installed")
class RuffPolicyTests(unittest.TestCase):
    def findings(self, filename, source):
        result = subprocess.run(  # noqa: S603 -- Resolve installed Ruff; pass fixture source only through stdin.
            [
                RUFF,
                "check",
                "--no-cache",
                "--no-fix",
                "--extend-select",
                "PT009,PT027",
                "--output-format",
                "json",
                "--stdin-filename",
                filename,
                "-",
            ],
            input=source,
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
            timeout=10,
        )
        self.assertIn(result.returncode, (0, 1), result.stderr)
        return {finding["code"] for finding in json.loads(result.stdout)}

    def test_test_exemptions_apply_to_both_test_locations(self):
        for filename in ("tests/test_example.py", ".github/workflows/test_example.py"):
            with self.subTest(filename=filename):
                codes = self.findings(filename, "def example(value):\n    return value\n")
                self.assertFalse({code for code in codes if code.startswith(("ANN", "D"))}, codes)

    def test_stdlib_unittest_assertions_remain_supported(self):
        source = (
            "import unittest\n\nclass ExampleTests(unittest.TestCase):\n"
            "    def test_example(self):\n        self.assertEqual(1, 1)\n"
            '        with self.assertRaises(ValueError):\n            raise ValueError("Expected failure")\n'
        )
        for filename in ("tests/test_example.py", ".github/workflows/test_example.py"):
            with self.subTest(filename=filename):
                codes = self.findings(filename, source)
                self.assertFalse({"PT009", "PT027"} & codes, codes)

    def test_runtime_helpers_keep_annotation_and_docstring_checks(self):
        for filename in ("scripts/doctor.py", "scripts/vm-test.py", ".github/workflows/extract-image.py"):
            with self.subTest(filename=filename):
                codes = self.findings(filename, "def example(value):\n    return value\n")
                self.assertTrue({"ANN001", "ANN201", "D103"} <= codes, codes)

    def test_cli_message_exemptions_do_not_disable_security_checks(self):
        source = (
            'import subprocess\n\ncommand = ["example"]\n'
            'subprocess.run(command, check=True)\nraise ValueError("Invalid input value")\n'
        )
        for filename in ("scripts/doctor.py", "scripts/vm-test.py", ".github/workflows/extract-image.py"):
            with self.subTest(filename=filename):
                codes = self.findings(filename, source)
                self.assertFalse({"TRY003", "EM101", "EM102"} & codes, codes)
                self.assertIn("S603", codes)


if __name__ == "__main__":
    unittest.main()
