"""Guard Pages publishing refs, artifact scope and deployment permissions."""

import tomllib
import unittest
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]


class DocsWorkflowTests(unittest.TestCase):
    """Keep untrusted builds outside the Pages deployment boundary."""

    @classmethod
    def setUpClass(cls) -> None:
        """Read expressions literally instead of coercing YAML keys such as 'on'."""
        cls.workflow = yaml.load(
            (ROOT / ".github/workflows/docs.yml").read_text(encoding="utf-8"),
            Loader=yaml.BaseLoader,
        )
        cls.build = cls.workflow["jobs"]["build"]
        cls.deploy = cls.workflow["jobs"]["deploy"]

    def test_publish_only_successful_trunk_builds_not_pull_requests(self) -> None:
        """Require the same trusted ref for artifact upload and deployment."""
        self.assertEqual(set(self.workflow["on"]), {"push", "pull_request", "workflow_dispatch"})
        self.assertEqual(self.workflow["on"]["push"]["branches"], ["trunk"])
        self.assertEqual(self.deploy["needs"], "build")
        self.assertEqual(
            self.deploy["if"],
            "github.event_name != 'pull_request' && github.ref == 'refs/heads/trunk'",
        )
        upload = self.build["steps"][-1]
        self.assertTrue(upload["uses"].startswith("actions/upload-pages-artifact@"))
        self.assertEqual(upload["if"], self.deploy["if"])
        self.assertEqual(upload["with"], {"path": "site/", "retention-days": "1"})
        self.assertEqual(self.build["steps"][-2]["run"], "mise run docs-build")

    def test_only_deploy_job_can_publish(self) -> None:
        """Keep elevated permissions away from checked-out repository code."""
        self.assertEqual(self.workflow["permissions"], {"contents": "read"})
        self.assertNotIn("permissions", self.build)
        self.assertEqual(self.deploy["permissions"], {"pages": "write", "id-token": "write"})
        self.assertEqual(self.build["steps"][0]["with"]["persist-credentials"], "false")
        self.assertEqual(self.deploy["environment"]["name"], "github-pages")
        self.assertEqual(
            self.deploy["concurrency"],
            {"group": "github-pages", "cancel-in-progress": "false"},
        )
        self.assertEqual(len(self.deploy["steps"]), 1)
        self.assertTrue(self.deploy["steps"][0]["uses"].startswith("actions/deploy-pages@"))

    def test_site_uses_project_base_url_and_matches_upload_directory(self) -> None:
        """Publish only generated output with the GitHub project URL prefix."""
        with (ROOT / "zensical.toml").open("rb") as config:
            project = tomllib.load(config)["project"]
        self.assertEqual(project["site_url"], "https://digitalr00ts.github.io/kickstart/")
        self.assertEqual(project["site_dir"], self.build["steps"][-1]["with"]["path"].rstrip("/"))


if __name__ == "__main__":
    unittest.main()
