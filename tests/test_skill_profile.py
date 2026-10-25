import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


MODULE = Path(__file__).resolve().parents[1] / "home/private_dot_config/mise/skill-profile/profile.py"
SPEC = importlib.util.spec_from_file_location("skill_profile", MODULE)
profile = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(profile)


class SkillProfileTests(unittest.TestCase):
    def test_only_entry_points_are_automatic_and_every_skill_is_invocable(self):
        policy = profile.read_policy()
        for name in ["poteto-mode", "architect", "principle-boundary-discipline", "grilling"]:
            text = f"---\nname: {name}\ndescription: Example\nuser-invocable: false\npaths: [\"*.ts\"]\ndisable-model-invocation: true\n---\nBody\n"
            result = profile.rewrite_skill(text, name in policy["automatic"])
            header, body = profile.frontmatter(result)
            self.assertIn("user-invocable: true", header)
            self.assertEqual(header.count("disable-model-invocation:"), 1)
            self.assertIn(f"disable-model-invocation: {str(name not in policy['automatic']).lower()}", header)
            self.assertNotIn("paths:", header)
            self.assertEqual(body, "\nBody\n")

    def test_sync_is_idempotent_and_upstream_is_unchanged(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            source = home / ".local/share/mise/installs/http-pstack/latest"
            skills = source / "plugins/pstack/skills"
            originals = {}
            for name in ["poteto-mode", "architect", "setup-pstack"]:
                file = skills / name / "SKILL.md"
                file.parent.mkdir(parents=True)
                file.write_text(f"---\nname: {name}\ndescription: Example\n---\nBody\n")
                originals[file] = file.read_bytes()
            helper = skills / "setup-pstack/scripts/read-sheet.sh"
            helper.parent.mkdir()
            helper.write_text("helper")
            for name in ["emil", "matt"]:
                (home / f".local/share/mise/installs/http-{name}-skills/latest/skills").mkdir(parents=True)
            policy = {"automatic": ["poteto-mode"], "removed": ["setup-pstack"], "sources": [
                {"name": "pstack", "path": "http-pstack/latest", "root": ".", "skills": "plugins/pstack/skills"},
                {"name": "emil", "path": "http-emil-skills/latest", "root": "skills", "skills": "."},
                {"name": "matt", "path": "http-matt-skills/latest", "root": "skills", "skills": "."},
            ]}
            destination = home / "output"
            profile.sync(home, destination, policy)
            first = (destination / "current").resolve()
            profile.sync(home, destination, policy)
            self.assertEqual(first, (destination / "current").resolve())
            profile.verify(destination, policy)
            manifest = json.loads((first / "manifest.json").read_text())
            self.assertEqual({entry["name"] for entry in manifest["skills"]}, {"poteto-mode", "architect"})
            self.assertTrue((first / "pstack/plugins/pstack/skills/setup-pstack/scripts/read-sheet.sh").exists())
            for file, contents in originals.items():
                self.assertEqual(file.read_bytes(), contents)


if __name__ == "__main__":
    unittest.main()
