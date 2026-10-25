import importlib.util
import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


MODULE = Path(__file__).resolve().parents[1] / "home/private_dot_config/mise/skill-profile/hermes_profile.py"
SPEC = importlib.util.spec_from_file_location("hermes_profile", MODULE)
hermes_profile = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(hermes_profile)


def make_skill(path, name, body=None):
    path.mkdir(parents=True, exist_ok=True)
    text = "---\n" + json.dumps({"name": name, "description": f"Use {name} for the fixture."}) + "\n---\n"
    (path / "SKILL.md").write_text(text + (body or f"# {name}\n\nDistinct fixture body for {name}.\n"))
    (path / "scripts").mkdir(exist_ok=True)
    (path / "scripts/run.txt").write_text(f"support data for {name}")
    return path


def make_profile(root):
    entries = []
    for name in sorted(hermes_profile.CORE | {"tdd", "handoff"}):
        path = make_skill(root / "source" / name, name)
        entries.append({"name": name, "path": str(path.relative_to(root)), "automatic": name in hermes_profile.CORE})
    (root / "manifest.json").write_text(json.dumps({"automatic": sorted(hermes_profile.CORE), "skills": entries}))
    return root


class FixtureHermes:
    def __init__(self):
        self.configuration = {}
        self.calls = 0

    def inspect(self, files, bundles):
        skills = {}
        for file in files:
            skills[str(file)] = json.loads(file.read_text().split("---", 2)[1])
        existing = {}
        for file in sorted(bundles.glob("*.yaml")):
            data = json.loads(file.read_text())
            existing[hermes_profile.slugify(data["name"])] = {"path": str(file), "data": data}
        return {"skills": skills, "bundles": existing, "reserved": ["handoff", "help", "reset"],
                "excluded": [".archive", ".git", ".previous", "node_modules"]}

    def configure(self, destination):
        self.configuration.update({"external_dirs": [str(destination)], "auto_load": []})
        self.calls += 1


class HermesProfileTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.home = self.root / "home"
        self.home.mkdir()
        self.profile = make_profile(self.root / "profile")
        self.destination = self.root / "hermes"
        self.local = self.home / ".hermes/skills"
        self.native = FixtureHermes()

    def sync(self):
        return hermes_profile.sync(self.profile, self.home, self.destination, self.native)

    def test_core_visible_archive_links_and_originals_preserved(self):
        original = make_skill(self.local / "custom/iitd-coursework", "iitd-coursework")
        make_skill(self.local / "autonomous-ai-agents/hermes-agent", "hermes-agent")
        (original / "data.bin").write_bytes(b"\x00\xff")
        result = self.sync()
        self.assertEqual(result["visible"], sorted(hermes_profile.CORE | {"hermes-agent"}))
        archived = self.local / ".archive/custom/iitd-coursework"
        self.assertFalse(original.exists())
        self.assertEqual((archived / "data.bin").read_bytes(), b"\x00\xff")
        self.assertTrue((self.local / "autonomous-ai-agents/hermes-agent/SKILL.md").exists())
        self.assertEqual((self.destination / ".archive/profile/tdd").resolve(),
                         (self.profile / "source/tdd").resolve())
        self.assertEqual(self.native.configuration["auto_load"], [])
        self.assertEqual(self.native.configuration["external_dirs"], [str(self.destination)])
        commands = json.loads((self.destination / "manifest.json").read_text())["commands"]
        self.assertIn("profile-handoff", [entry["command"] for entry in commands])
        self.assertIn(".archive/custom/iitd-coursework", [entry["identifier"] for entry in commands])

    def test_sync_twice_changes_no_files_or_original_skill_content(self):
        make_skill(self.local / "custom/mochi-sync", "mochi-sync")
        self.sync()
        files = {p: (p.read_bytes(), p.stat().st_mtime_ns) for p in self.root.rglob("*")
                 if p.is_file() and not p.is_symlink()}
        self.assertEqual(self.sync()["archived"], 0)
        self.assertEqual(files, {p: (p.read_bytes(), p.stat().st_mtime_ns) for p in files})

    def test_existing_bundle_and_native_name_collision_get_separate_commands(self):
        custom = self.home / ".hermes/skill-bundles/tdd.yaml"
        custom.parent.mkdir(parents=True)
        content = json.dumps({"name": "tdd", "skills": ["original-tdd"]})
        custom.write_text(content)
        make_skill(self.local / "coding/tdd", "tdd")
        self.sync()
        self.assertEqual(custom.read_text(), content)
        commands = json.loads((self.destination / "manifest.json").read_text())["commands"]
        self.assertEqual({entry["command"] for entry in commands if entry["name"] == "tdd"},
                         {"profile-tdd", "native-tdd"})
        self.sync()
        self.assertEqual(custom.read_text(), content)

    def test_identical_reinstalled_skill_preserved_in_previous_archive(self):
        original = make_skill(self.local / "coding/native", "native")
        self.sync()
        shutil.copytree(self.local / ".archive/coding/native", original)
        result = self.sync()
        self.assertEqual(result["archived"], 1)
        self.assertTrue((self.local / ".archive/.previous/coding/native.1/SKILL.md").is_file())
        self.assertTrue((self.local / ".archive/coding/native/SKILL.md").is_file())
        self.assertEqual(self.sync()["archived"], 0)

    def test_changed_reinstall_collision_stops_before_any_move(self):
        archived = make_skill(self.local / ".archive/coding/native", "native")
        incoming = make_skill(self.local / "coding/native", "native", "new version")
        other = make_skill(self.local / "custom/other", "other")
        with self.assertRaisesRegex(FileExistsError, "archive content differs"):
            self.sync()
        self.assertEqual((incoming / "SKILL.md").read_text().split("---", 2)[2].strip(), "new version")
        self.assertTrue(archived.exists())
        self.assertTrue(other.exists())
        self.assertEqual(self.native.calls, 0)

    def test_support_skill_files_are_not_moved_independently(self):
        original = make_skill(self.local / "custom/coursework", "coursework")
        make_skill(original / "references/example", "example")
        self.sync()
        self.assertTrue((self.local / ".archive/custom/coursework/references/example/SKILL.md").exists())
        commands = json.loads((self.destination / "manifest.json").read_text())["commands"]
        self.assertNotIn("example", [entry["name"] for entry in commands])

    def test_core_original_is_not_overwritten_or_ambiguous(self):
        original = make_skill(self.local / "custom/grilling", "grilling", "user original")
        self.sync()
        self.assertEqual((original / "SKILL.md").read_text().split("---", 2)[2].strip(), "user original")
        self.assertEqual((self.destination / "core/grilling").resolve(), original.resolve())

    def test_native_slugs_and_reserved_commands_are_not_shadowed(self):
        self.assertEqual(hermes_profile.slugify("Git_helper"), "git-helper")
        self.assertEqual(hermes_profile.slugify("小说拆条"), "小说拆条")
        make_skill(self.local / "custom/help", "help")
        self.sync()
        commands = json.loads((self.destination / "manifest.json").read_text())["commands"]
        self.assertIn("native-help", [entry["command"] for entry in commands])
        self.assertFalse({"help", "handoff", "reset"} & {entry["command"] for entry in commands})

    def test_bad_profile_path_fails_without_native_mutations(self):
        manifest = json.loads((self.profile / "manifest.json").read_text())
        manifest["skills"][0]["path"] = "../outside"
        (self.profile / "manifest.json").write_text(json.dumps(manifest))
        with self.assertRaisesRegex(ValueError, "inside the snapshot"):
            self.sync()
        self.assertEqual(self.native.calls, 0)

    def test_original_destination_directory_is_not_replaced(self):
        original = self.destination / ".archive/profile/tdd"
        make_skill(original, "original")
        with self.assertRaisesRegex(FileExistsError, "original directory"):
            self.sync()
        self.assertEqual((original / "scripts/run.txt").read_text(), "support data for original")

    @unittest.skipUnless(os.environ.get("HERMES_TEST_BINARY"), "set HERMES_TEST_BINARY to the installed native Hermes binary")
    def test_native_discovery_and_bundles_with_temporary_home(self):
        binary = Path(os.environ["HERMES_TEST_BINARY"])
        original = make_skill(self.local / "custom/mochi-sync", "mochi-sync")
        make_skill(self.local / "autonomous-ai-agents/hermes-agent", "hermes-agent")
        config = self.home / ".hermes/config.yaml"
        config.write_text(json.dumps({"model": "keep-this-model", "curator": {"enabled": True},
                                     "skills": {"auto_load": ["tdd"], "template_vars": {"course": "keep-this"}}}))
        environment = dict(os.environ, PYTHONDONTWRITEBYTECODE="1")
        command = [str(binary.parent.parent.resolve() / ".venv/bin/python"), str(MODULE),
                   "--profile", str(self.profile), "--home", str(self.home),
                   "--destination", str(self.destination), "--hermes", str(binary)]
        for operation in ("sync", "sync", "verify"):
            result = subprocess.run([*command, operation], text=True, capture_output=True, env=environment)
            self.assertEqual(result.returncode, 0, result.stderr)
            output = json.loads(result.stdout)
            print(json.dumps({"native_operation": operation, "result": output}))
        self.assertFalse(original.exists())
        self.assertEqual((self.local / ".archive/custom/mochi-sync/scripts/run.txt").read_text(),
                         "support data for mochi-sync")
        runtime = hermes_profile.Hermes(binary, self.home)
        result = runtime.run("""
import json, yaml
from hermes_constants import get_hermes_home
data = yaml.safe_load((get_hermes_home() / "config.yaml").read_text())
print(json.dumps({"model": data["model"], "curator": data["curator"],
                  "template_vars": data["skills"]["template_vars"]}))
""", {})
        self.assertEqual(result, {"model": "keep-this-model", "curator": {"enabled": True},
                                  "template_vars": {"course": "keep-this"}})


if __name__ == "__main__":
    unittest.main()
