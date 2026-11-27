"""Statically guard image workflow trust boundaries and diagnostic upload scope."""

import shlex
import unittest
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]


class ImageWorkflowTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workflow = yaml.load(
            (ROOT / ".github/workflows/test-image.yml").read_text(encoding="utf-8"),
            Loader=yaml.BaseLoader,
        )
        cls.job = cls.workflow["jobs"]["test"]
        cls.steps = cls.job["steps"]

    def test_only_manual_and_completed_main_build_triggers(self):
        self.assertEqual(set(self.workflow["on"]), {"workflow_dispatch", "workflow_run"})
        self.assertEqual(
            self.workflow["on"]["workflow_run"],
            {"workflows": ["Build"], "types": ["completed"], "branches": ["main"]},
        )
        self.assertNotIn("workflow_call", self.workflow["on"])
        self.assertNotIn("uses", self.job)

    def test_job_requires_manual_dispatch_or_trusted_successful_push(self):
        self.assertEqual(
            " ".join(self.job["if"].split()),
            "github.event_name == 'workflow_dispatch' || "
            "(github.event_name == 'workflow_run' && "
            "github.event.workflow_run.conclusion == 'success' && "
            "github.event.workflow_run.event == 'push' && "
            "github.event.workflow_run.head_branch == 'main' && "
            "github.event.workflow_run.head_repository.full_name == github.repository)",
        )

    def test_permissions_remain_read_only_without_job_overrides(self):
        self.assertEqual(self.workflow["permissions"], {"contents": "read", "actions": "read"})
        for job in self.workflow["jobs"].values():
            self.assertNotIn("permissions", job)

    def test_checkout_uses_exact_build_sha_or_manual_dispatch_sha(self):
        checkouts = [step for step in self.steps if step.get("uses", "").startswith("actions/checkout@")]
        self.assertTrue(checkouts)
        for checkout in checkouts:
            self.assertEqual(
                checkout["with"]["ref"],
                "${{ github.event_name == 'workflow_run' && github.event.workflow_run.head_sha || github.sha }}",
            )
            self.assertNotIn("repository", checkout["with"])

    def test_selector_and_download_bind_to_requested_or_triggering_build_run(self):
        selector = next(step for step in self.steps if step.get("id") == "artifact")
        self.assertEqual(selector["env"]["REQUESTED_RUN"], "${{ inputs.run_id || github.event.workflow_run.id }}")
        self.assertEqual(selector["env"]["REQUESTED_ARTIFACT"], "${{ inputs.artifact_name }}")
        self.assertIn("./scripts/select-artifact.cjs", selector["with"]["script"])
        downloads = [step for step in self.steps if step.get("uses", "").startswith("actions/download-artifact@")]
        self.assertTrue(downloads)
        for download in downloads:
            self.assertEqual(download["with"]["repository"], "${{ github.repository }}")
            self.assertEqual(download["with"]["run-id"], "${{ steps.artifact.outputs.run_id }}")
            self.assertEqual(download["with"]["name"], "${{ steps.artifact.outputs.name }}")
            self.assertLess(self.steps.index(selector), self.steps.index(download))

    def test_cleanup_and_failure_upload_declarations_allow_only_snapshot_logs(self):
        configuration = next(step for step in self.steps if "VM_LOG_DIR" in step.get("env", {}))
        self.assertEqual(configuration["env"]["VM_LOG_DIR"], "${{ runner.temp }}/vm-test-logs")

        molecule = next(step for step in self.steps if step.get("id") == "molecule")
        self.assertLess(self.steps.index(configuration), self.steps.index(molecule))
        cleanup = next(step for step in self.steps if step.get("id") == "cleanup")
        self.assertEqual(shlex.split(molecule["run"]), ["mise", "run", "test"])
        cleanup_argv = shlex.split(cleanup["run"])
        self.assertEqual(cleanup_argv[:2], ["uv", "run"])
        self.assertEqual(cleanup_argv[-4:], ["molecule", "destroy", "-s", "qemu"])
        self.assertEqual(cleanup["if"], "always() && steps.molecule.outcome != 'skipped'")
        self.assertNotIn("continue-on-error", molecule)
        self.assertNotIn("continue-on-error", cleanup)
        self.assertLess(self.steps.index(molecule), self.steps.index(cleanup))
        uploads = [step for step in self.steps if step.get("uses", "").startswith("actions/upload-artifact@")]
        self.assertTrue(uploads)
        for upload in uploads:
            self.assertLess(self.steps.index(cleanup), self.steps.index(upload))
            self.assertEqual(upload["if"], "failure()")
            self.assertEqual(
                upload["with"]["path"].splitlines(),
                ["${{ env.VM_LOG_DIR }}/console.log", "${{ env.VM_LOG_DIR }}/supervisor.log"],
            )
            self.assertEqual(upload["with"]["if-no-files-found"], "ignore")
            self.assertNotIn("include-hidden-files", upload["with"])


if __name__ == "__main__":
    unittest.main()
