"""Assert security properties of the shipped image, not the customized test disk."""

from pathlib import Path
import unittest

import yaml

ROOT = Path(__file__).resolve().parents[1]


class ImageSecurityTests(unittest.TestCase):
    def test_accounts_have_no_shared_password(self):
        image = yaml.safe_load((ROOT / "kiwi/fedora-44.kiwi").read_text())["image"]
        self.assertEqual(image["users"]["user"]["@password"], "!")
        script = (ROOT / "kiwi/config.sh").read_text()
        self.assertIn("passwd -l root\n", script)
        self.assertIn("passwd -l admin\n", script)
        self.assertNotIn("passwd -l root || true", script)

    def test_image_disables_password_and_root_ssh(self):
        script = (ROOT / "kiwi/config.sh").read_text()
        for setting in (
            "PasswordAuthentication no",
            "KbdInteractiveAuthentication no",
            "PermitRootLogin no",
            "PubkeyAuthentication yes",
        ):
            self.assertIn(setting, script)
        self.assertNotIn("NOPASSWD", script)
        self.assertNotIn("ssh-ed25519 ", script)

    def test_image_explicitly_installs_enabled_services_and_test_prerequisites(self):
        image = yaml.safe_load((ROOT / "kiwi/fedora-44.kiwi").read_text())["image"]
        packages = {
            package["@name"]
            for group in image["packages"]
            if group.get("@type") == "image" and "@profiles" not in group
            for package in group.get("package", [])
        }
        self.assertTrue({"openssh-server", "NetworkManager", "firewalld", "sudo", "python3"} <= packages)


if __name__ == "__main__":
    unittest.main()
