"""Guard image-test automation trust boundaries and public diagnostic uploads."""

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
        self.assertEqual(set(self.workflow["jobs"]), {"test"})
        self.assertNotIn("permissions", self.job)

    def test_manual_inputs_and_automatic_native_x86_default(self):
        inputs = self.workflow["on"]["workflow_dispatch"]["inputs"]
        self.assertEqual(set(inputs), {"arch", "run_id", "artifact_name"})
        self.assertEqual(inputs["arch"]["default"], "x86_64")
        self.assertEqual(inputs["arch"]["type"], "choice")
        self.assertEqual(inputs["arch"]["options"], ["x86_64", "aarch64"])
        for name in ("run_id", "artifact_name"):
            with self.subTest(input=name):
                self.assertEqual(inputs[name]["type"], "string")
                self.assertEqual(inputs[name]["required"], "false")
        self.assertEqual(self.job["env"]["IMAGE_ARCH"], "${{ inputs.arch || 'x86_64' }}")
        self.assertEqual(
            self.job["runs-on"],
            "${{ inputs.arch == 'aarch64' && 'ubuntu-24.04-arm' || 'ubuntu-24.04' }}",
        )
        self.assertNotIn("strategy", self.job)

    def test_checkout_uses_exact_build_sha_or_manual_dispatch_sha(self):
        checkouts = [step for step in self.steps if step.get("uses", "").startswith("actions/checkout@")]
        self.assertEqual(len(checkouts), 1)
        self.assertIs(self.steps[0], checkouts[0])
        self.assertEqual(
            checkouts[0]["with"]["ref"],
            "${{ github.event_name == 'workflow_run' && github.event.workflow_run.head_sha || github.sha }}",
        )
        self.assertNotIn("repository", checkouts[0]["with"])

    def test_selector_and_download_bind_to_requested_or_triggering_build_run(self):
        selector = next(step for step in self.steps if step.get("id") == "artifact")
        self.assertEqual(selector["env"]["REQUESTED_RUN"], "${{ inputs.run_id || github.event.workflow_run.id }}")
        self.assertEqual(selector["env"]["REQUESTED_ARTIFACT"], "${{ inputs.artifact_name }}")
        self.assertIn("require('./scripts/select-artifact.cjs')", selector["with"]["script"])
        self.assertIn("await selectArtifact({ github, context, core });", selector["with"]["script"])
        download = next(step for step in self.steps if step.get("uses", "").startswith("actions/download-artifact@"))
        self.assertEqual(download["with"]["repository"], "${{ github.repository }}")
        self.assertEqual(download["with"]["run-id"], "${{ steps.artifact.outputs.run_id }}")
        self.assertEqual(download["with"]["name"], "${{ steps.artifact.outputs.name }}")
        self.assertLess(self.steps.index(selector), self.steps.index(download))

    def test_failure_upload_whitelists_only_runtime_snapshot_logs(self):
        configuration = next(step for step in self.steps if "VM_LOG_DIR" in step.get("env", {}))
        self.assertEqual(configuration["env"]["VM_LOG_DIR"], "${{ runner.temp }}/vm-test-logs")
        self.assertEqual(configuration["run"], 'printf \'VM_LOG_DIR=%s\\n\' "$VM_LOG_DIR" >> "$GITHUB_ENV"')
        molecule = next(step for step in self.steps if step.get("id") == "molecule")
        self.assertLess(self.steps.index(configuration), self.steps.index(molecule))
        uploads = [step for step in self.steps if step.get("uses", "").startswith("actions/upload-artifact@")]
        self.assertEqual(len(uploads), 1)
        upload = uploads[0]
        self.assertEqual(upload["if"], "failure()")
        self.assertEqual(upload["uses"], "actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a")
        self.assertEqual(
            upload["with"]["path"].splitlines(),
            ["${{ env.VM_LOG_DIR }}/console.log", "${{ env.VM_LOG_DIR }}/supervisor.log"],
        )
        self.assertEqual(upload["with"]["retention-days"], "7")
        self.assertEqual(upload["with"]["if-no-files-found"], "ignore")
        self.assertNotIn("include-hidden-files", upload["with"])

    def test_cleanup_runs_after_failed_startup_and_before_failure_upload(self):
        molecule = next(step for step in self.steps if step.get("id") == "molecule")
        cleanup = next(step for step in self.steps if step.get("id") == "cleanup")
        upload = next(step for step in self.steps if step.get("uses", "").startswith("actions/upload-artifact@"))
        self.assertEqual(molecule["run"], "mise run test")
        self.assertEqual(cleanup["if"], "always() && steps.molecule.outcome != 'skipped'")
        self.assertEqual(cleanup["run"], "uv run --group test --frozen molecule destroy -s qemu")
        self.assertNotIn("continue-on-error", molecule)
        self.assertNotIn("continue-on-error", cleanup)
        self.assertLess(self.steps.index(molecule), self.steps.index(cleanup))
        self.assertLess(self.steps.index(cleanup), self.steps.index(upload))


if __name__ == "__main__":
    unittest.main()
