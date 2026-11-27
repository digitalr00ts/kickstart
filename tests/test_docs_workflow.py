"""Statically guard Pages publishing refs, output scope and permission separation."""

import tomllib
import unittest
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]


class DocsWorkflowTests(unittest.TestCase):
    """Check declarations, not GitHub Actions execution or deployment success."""

    @classmethod
    def setUpClass(cls) -> None:
        """Read expressions literally instead of coercing YAML keys such as 'on'."""
        cls.workflow = yaml.load(
            (ROOT / ".github/workflows/docs.yml").read_text(encoding="utf-8"),
            Loader=yaml.BaseLoader,
        )
        cls.build = cls.workflow["jobs"]["build"]
        cls.deploy = cls.workflow["jobs"]["deploy"]
        cls.uploads = [
            step for step in cls.build["steps"] if step.get("uses", "").startswith("actions/upload-pages-artifact@")
        ]

    def test_publishing_requires_trunk_and_build_dependency(self) -> None:
        """Require the same trusted ref for artifact upload and deployment."""
        self.assertEqual(set(self.workflow["on"]), {"push", "pull_request", "workflow_dispatch"})
        self.assertEqual(self.workflow["on"]["push"]["branches"], ["trunk"])
        self.assertEqual(self.deploy["needs"], "build")
        self.assertEqual(
            self.deploy["if"],
            "github.event_name != 'pull_request' && github.ref == 'refs/heads/trunk'",
        )
        self.assertTrue(self.uploads)
        for upload in self.uploads:
            self.assertEqual(upload["if"], self.deploy["if"])

    def test_only_deploy_job_can_publish(self) -> None:
        """Keep elevated permissions away from checked-out repository code."""
        self.assertEqual(self.workflow["permissions"], {"contents": "read"})
        for name, job in self.workflow["jobs"].items():
            if name != "deploy":
                self.assertNotIn("permissions", job)
        self.assertEqual(self.deploy["permissions"], {"pages": "write", "id-token": "write"})
        checkouts = [step for step in self.build["steps"] if step.get("uses", "").startswith("actions/checkout@")]
        self.assertTrue(checkouts)
        for checkout in checkouts:
            self.assertEqual(checkout["with"]["persist-credentials"], "false")
        self.assertEqual(self.deploy["environment"]["name"], "github-pages")
        self.assertEqual(
            self.deploy["concurrency"],
            {"group": "github-pages", "cancel-in-progress": "false"},
        )
        self.assertTrue(self.deploy["steps"])
        for step in self.deploy["steps"]:
            self.assertTrue(step.get("uses", "").startswith("actions/deploy-pages@"))
            self.assertNotIn("run", step)

    def test_upload_directory_matches_generated_site(self) -> None:
        """Upload the configured build output rather than repository contents."""
        with (ROOT / "zensical.toml").open("rb") as config:
            project = tomllib.load(config)["project"]

        self.assertTrue(self.uploads)
        for upload in self.uploads:
            self.assertEqual(project["site_dir"], upload["with"]["path"].rstrip("/"))


if __name__ == "__main__":
    unittest.main()
