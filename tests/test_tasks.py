"""Keep the no-VM contributor entry points aligned with their documented scope."""

import shlex
import tomllib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class TaskTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with (ROOT / "pyproject.toml").open("rb") as config:
            cls.tasks = tomllib.load(config)["tool"]["poe"]["tasks"]

    def test_check_all_includes_each_suite_without_hooks_or_guests(self):
        self.assertEqual(self.tasks["check-all"]["sequence"],
                         ["check", "check-artifacts", "check-workflows"])
        self.assertEqual(shlex.split(self.tasks["check"]["cmd"]), [
            "uv", "run", "--group", "test", "--frozen", "python", "-m", "unittest",
            "discover", "-s", "tests", "-p", "test_*.py"])
        self.assertEqual(shlex.split(self.tasks["check-workflows"]["cmd"]), [
            "uv", "run", "--group", "test", "--frozen", "python", "-m", "unittest",
            "discover", "-s", ".github/workflows", "-p", "test_*.py"])
        artifact_command = shlex.split(self.tasks["check-artifacts"]["cmd"])
        self.assertEqual(artifact_command[:2], ["node", "--test"])
        self.assertEqual(set(artifact_command[2:]), {
            str(path.relative_to(ROOT)) for path in (ROOT / "tests").glob("test_*.cjs")})

    def test_doctor_runs_standalone_without_build_or_test_dependencies(self):
        self.assertEqual(self.tasks["doctor"]["cmd"], "python scripts/doctor.py")
        self.assertTrue((ROOT / "scripts/doctor.py").is_file())


if __name__ == "__main__":
    unittest.main()
