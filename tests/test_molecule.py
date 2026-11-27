"""Validate Molecule contracts against its installed schema, without booting a VM."""

import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import PropertyMock, patch

import yaml
from molecule.config import Config
from molecule.model.schema_v3 import validate

ROOT = Path(__file__).resolve().parents[1]
DEFAULT = ROOT / "molecule/default"


class MoleculeTests(unittest.TestCase):
    def scenarios(self):
        for scenario in ("qemu",):
            path = ROOT / "molecule" / scenario / "molecule.yml"
            yield path, yaml.safe_load(path.read_text())

    def test_boot_wait_is_bounded_and_requires_running_state(self):
        tasks = yaml.safe_load((DEFAULT / "verify-common.yml").read_text())
        (boot_task,) = [
            task for task in tasks if task.get("ansible.builtin.command") == "systemctl is-system-running --wait"
        ]
        self.assertIsInstance(boot_task["timeout"], int)
        self.assertGreater(boot_task["timeout"], 0)
        self.assertLessEqual(boot_task["timeout"], 240)
        self.assertEqual(boot_task["register"], "boot_status")
        self.assertFalse(boot_task["changed_when"])
        self.assertEqual(boot_task["failed_when"], "boot_status.rc not in [0, 1]")
        assertions = [
            condition
            for task in tasks
            if "ansible.builtin.assert" in task
            for condition in task["ansible.builtin.assert"]["that"]
        ]
        self.assertIn("boot_status.stdout | trim == 'running'", assertions)

    def test_installed_schema_and_default_driver(self):
        for path, config in self.scenarios():
            with self.subTest(scenario=path.parent.name):
                self.assertEqual(validate(config), [])
                self.assertEqual(config["driver"]["name"], "default")
                self.assertTrue(config["driver"]["options"]["managed"])

    def test_lifecycle_reaches_verification_and_finishes_with_cleanup(self):
        for path, config in self.scenarios():
            with self.subTest(scenario=path.parent.name):
                sequence = config["scenario"]["test_sequence"]
                self.assertLess(sequence.index("create"), sequence.index("converge"))
                self.assertLess(sequence.index("converge"), sequence.index("verify"))
                self.assertEqual(sequence[-1], "destroy")
                self.assertFalse(config["dependency"]["enabled"])
                for action in ("create", "converge", "verify", "destroy"):
                    relative = config["provisioner"].get("playbooks", {}).get(action, action + ".yml")
                    self.assertEqual((path.parent / relative).resolve(), (DEFAULT / f"{action}.yml").resolve())
                for action in ("converge", "verify"):
                    (play,) = yaml.safe_load((DEFAULT / f"{action}.yml").read_text())
                    self.assertEqual(play["hosts"], "molecule")
                (verify,) = yaml.safe_load((DEFAULT / "verify.yml").read_text())
                self.assertTrue(
                    any(task.get("ansible.builtin.include_tasks") == "verify-common.yml" for task in verify["tasks"])
                )

    def test_instance_config_populates_actual_driver_inventory(self):
        with tempfile.TemporaryDirectory() as temporary:
            instance_config = Path(temporary) / "instance_config.yml"
            instance_config.write_text(
                json.dumps(
                    [
                        {
                            "instance": "instance",
                            "address": "127.0.0.1",
                            "port": 2345,
                            "user": "admin",
                            "identity_file": str(Path(temporary) / "id_ed25519"),
                        }
                    ]
                )
            )
            for path, _ in self.scenarios():
                with self.subTest(scenario=path.parent.name):
                    config = Config(str(path))
                    with patch.object(
                        type(config.driver),
                        "instance_config",
                        new_callable=PropertyMock,
                        return_value=str(instance_config),
                    ):
                        host = config.provisioner.inventory["molecule"]["hosts"]["instance"]
                    self.assertEqual(host["ansible_host"], "127.0.0.1")
                    self.assertEqual(host["ansible_port"], 2345)
                    self.assertEqual(host["ansible_user"], "admin")
                    self.assertEqual(host["ansible_private_key_file"], str(Path(temporary) / "id_ed25519"))
                    self.assertIn("IdentitiesOnly=yes", host["ansible_ssh_common_args"])

    def test_local_lifecycle_calls_shared_python_runner(self):
        for action, command in [("create", "start"), ("destroy", "destroy")]:
            play = yaml.safe_load((DEFAULT / f"{action}.yml").read_text())[0]
            self.assertEqual(play["hosts"], "localhost")
            self.assertFalse(play["gather_facts"])
            (command_task,) = [task for task in play["tasks"] if "ansible.builtin.command" in task]
            argv = command_task["ansible.builtin.command"]["argv"]
            self.assertEqual(
                argv,
                [
                    "{{ ansible_playbook_python }}",
                    "{{ lookup('env', 'MOLECULE_PROJECT_DIRECTORY') }}/scripts/vm-test.py",
                    command,
                ],
            )

    def test_guest_checks_use_only_approved_read_only_operations(self):
        allowed_modules = {
            "ansible.builtin.assert",
            "ansible.builtin.command",
            "ansible.builtin.include_tasks",
            "ansible.builtin.package_facts",
            "ansible.builtin.service_facts",
            "ansible.builtin.setup",
            "ansible.builtin.stat",
            "ansible.builtin.wait_for_connection",
        }
        allowed_commands = {
            "id -un",
            "systemctl is-system-running --wait",
            "systemctl --failed --no-legend --plain --no-pager",
            "findmnt -n -o FSTYPE /",
            "python3 --version",
            "dnf --version",
        }
        for filename in ("converge.yml", "verify.yml", "verify-common.yml"):
            document = yaml.safe_load((DEFAULT / filename).read_text())
            if filename == "verify-common.yml":
                tasks = document
            else:
                tasks = []
                for play in document:
                    # Keep this guard scoped to the flat task lists it actually inspects.
                    for section in ("pre_tasks", "post_tasks", "handlers", "roles"):
                        self.assertFalse(play.get(section), f"Unchecked {section} in {filename}")
                    tasks.extend(play["tasks"])
            for task in tasks:
                with self.subTest(file=filename, task=task.get("name")):
                    modules = {key for key in task if "." in key}
                    self.assertEqual(len(modules), 1)
                    self.assertTrue(modules <= allowed_modules, modules)
                    if "ansible.builtin.command" in task:
                        self.assertIn(task["ansible.builtin.command"], allowed_commands)
                        self.assertFalse(task["changed_when"])
                    if "ansible.builtin.include_tasks" in task:
                        self.assertEqual(task["ansible.builtin.include_tasks"], "verify-common.yml")


if __name__ == "__main__":
    unittest.main()
