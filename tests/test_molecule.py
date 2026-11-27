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

    def test_qemu_is_the_only_runnable_scenario(self):
        self.assertEqual(
            sorted(
                path.relative_to(ROOT / "molecule").as_posix() for path in (ROOT / "molecule").rglob("molecule.yml")
            ),
            ["qemu/molecule.yml"],
        )

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

    def test_setup_collects_only_distribution_facts(self):
        (play,) = yaml.safe_load((DEFAULT / "verify.yml").read_text())
        self.assertFalse(play["gather_facts"])
        (setup_task,) = [task for task in play["tasks"] if "ansible.builtin.setup" in task]
        self.assertEqual(setup_task["ansible.builtin.setup"]["gather_subset"], ["!all", "!min", "distribution"])

    def test_installed_schema_and_default_driver(self):
        for path, config in self.scenarios():
            with self.subTest(scenario=path.parent.name):
                self.assertEqual(validate(config), [])
                self.assertEqual(config["driver"]["name"], "default")
                self.assertTrue(config["driver"]["options"]["managed"])

    def test_real_inventory_group_and_admin_without_become_override(self):
        for path, config in self.scenarios():
            with self.subTest(scenario=path.parent.name):
                self.assertEqual(config["platforms"], [{"name": "instance", "groups": ["molecule"]}])
                variables = config["provisioner"]["inventory"]["group_vars"]["molecule"]
                self.assertEqual(variables["ansible_user"], "admin")
                self.assertNotIn("ansible_become", variables)
                self.assertNotIn("ansible_port", variables)

    def test_full_test_sequence_and_existing_playbooks(self):
        for path, config in self.scenarios():
            with self.subTest(scenario=path.parent.name):
                self.assertEqual(
                    config["scenario"]["test_sequence"],
                    ["destroy", "syntax", "create", "converge", "verify", "destroy"],
                )
                self.assertFalse(config["dependency"]["enabled"])
                for action in ("create", "converge", "verify", "destroy"):
                    relative = config["provisioner"].get("playbooks", {}).get(action, action + ".yml")
                    self.assertTrue((path.parent / relative).is_file(), relative)

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

    def test_every_yaml_document_parses(self):
        for path in (ROOT / "molecule").rglob("*.yml"):
            with self.subTest(path=path):
                self.assertIsNotNone(yaml.safe_load(path.read_text()))

    def test_local_lifecycle_calls_shared_python_runner(self):
        for action, command in [("create", "start"), ("destroy", "destroy")]:
            play = yaml.safe_load((DEFAULT / f"{action}.yml").read_text())[0]
            self.assertEqual(play["hosts"], "localhost")
            self.assertFalse(play["gather_facts"])
            argv = play["tasks"][0]["ansible.builtin.command"]["argv"]
            self.assertEqual(
                argv,
                [
                    "{{ ansible_playbook_python }}",
                    "{{ lookup('env', 'MOLECULE_PROJECT_DIRECTORY') }}/scripts/vm-test.py",
                    command,
                ],
            )

    def test_verification_matches_image_without_installing_or_network(self):
        converge = (DEFAULT / "converge.yml").read_text()
        verify = (DEFAULT / "verify-common.yml").read_text()
        for forbidden in (
            "ansible.builtin.package:",
            "ansible.builtin.dnf:",
            "ping ",
            "8.8.8.8",
            "variant",
            "lvs",
            "strict_lvm",
        ):
            self.assertNotIn(forbidden, converge + verify)
        self.assertIn("'btrfs'", verify)
        self.assertIn("vim-minimal", verify)
        self.assertIn("/sys/firmware/efi", verify)
        self.assertIn("become: false", verify)
        for filename in ("converge.yml", "verify.yml"):
            play = yaml.safe_load((DEFAULT / filename).read_text())[0]
            self.assertEqual(play["hosts"], "molecule")
            self.assertTrue(play["become"])
            self.assertEqual(next(iter(play["tasks"][0].keys())), "name")
            self.assertIn("ansible.builtin.wait_for_connection", play["tasks"][0])

    def test_lima_guest_lifecycle_removed(self):
        self.assertEqual(list((ROOT / "molecule").rglob("*lima*")), [])
        self.assertFalse((ROOT / "molecule/shared").exists())


if __name__ == "__main__":
    unittest.main()
