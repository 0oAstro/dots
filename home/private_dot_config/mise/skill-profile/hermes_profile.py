import argparse
import filecmp
import json
import os
import re
import subprocess
import sys
from pathlib import Path


CORE = frozenset({"emil-design-eng", "grilling", "poteto-mode"})
ESSENTIAL = "hermes-agent"


INSPECT = """
import json, sys, yaml
from pathlib import Path
from agent.skill_utils import EXCLUDED_SKILL_DIRS
from agent.skill_commands import slugify_skill_name
from hermes_cli.commands import COMMAND_REGISTRY
request = json.load(sys.stdin)
skills = {}
for filename in request["files"]:
    text = Path(filename).read_text()
    parts = text.split("---", 2)
    header = yaml.safe_load(parts[1]) if len(parts) == 3 and not parts[0].strip() else {}
    name = header.get("name", Path(filename).parent.name)
    if not isinstance(name, str) or not name.strip():
        raise ValueError("skill has no name")
    skills[filename] = {"name": name, "description": str(header.get("description") or "")}
bundles = {}
directory = Path(request["bundles"])
for extension in ("*.yaml", "*.yml"):
    for file in sorted(directory.glob(extension)):
        data = yaml.safe_load(file.read_text())
        if not isinstance(data, dict):
            raise ValueError("bundle is not a mapping")
        slug = slugify_skill_name(str(data.get("name") or file.stem))
        if slug in bundles:
            raise ValueError("duplicate existing bundle command")
        bundles[slug] = {"path": str(file), "data": data}
reserved = {slugify_skill_name(n) for c in COMMAND_REGISTRY for n in (c.name, *c.aliases)}
print(json.dumps({"skills": skills, "bundles": bundles, "reserved": sorted(reserved),
                  "excluded": sorted(EXCLUDED_SKILL_DIRS)}))
"""


DISCOVER = """
import json, sys
from pathlib import Path
from agent.prompt_builder import build_skills_system_prompt
from agent.skill_commands import build_auto_load_prompt, get_skill_commands
from agent.skill_bundles import get_skill_bundles, build_bundle_invocation_message
from tools.skills_tool import skills_list, skill_view
request = json.load(sys.stdin)
problems = []
listed = json.loads(skills_list())
names = sorted(s["name"] for s in listed.get("skills", []))
if not listed.get("success") or names != sorted(request["visible"]):
    problems.append("visible skills differ: " + ", ".join(names))
index = build_skills_system_prompt(available_tools={"skill_view", "skills_list"},
                                   available_toolsets={"skills"})
for name in request["core"]:
    if name not in index:
        problems.append("core missing from index: " + name)
    source = Path(request["links"]["core/" + name], "SKILL.md")
    body = source.read_text().split("---", 2)[-1].strip()
    if body and body in index:
        problems.append("full core skill body appears in index: " + name)
preload, loaded, missing = build_auto_load_prompt()
if preload or loaded or missing:
    problems.append("skills.auto_load preloads content")
bundles = get_skill_bundles()
for entry in request["commands"]:
    key = "/" + entry["command"]
    if key not in bundles or bundles[key]["skills"] != [entry["identifier"]]:
        problems.append("bundle does not resolve: " + key)
        continue
    result = build_bundle_invocation_message(key, "verify")
    if result is None or result[1] != [entry["name"]] or result[2]:
        problems.append("bundle cannot load archived skill: " + key)
    viewed = json.loads(skill_view(entry["identifier"]))
    if not viewed.get("success"):
        problems.append("archive path cannot load: " + entry["identifier"])
    body = Path(entry["source"], "SKILL.md").read_text().split("---", 2)[-1].strip()
    if body and body in index:
        problems.append("full skill body appears in index: " + entry["name"])
print(json.dumps({"verified": not problems, "problems": problems, "visible": names,
                  "skill_commands": sorted(get_skill_commands()), "bundles": len(request["commands"]),
                  "essential_exception": "hermes-agent", "auto_load": loaded}))
"""


class Hermes:
    def __init__(self, binary, home):
        self.binary = binary.absolute()
        self.install = self.binary.parent.parent.resolve()
        self.python = self.install / ".venv/bin/python"
        if not self.binary.is_file() or not self.python.is_file():
            raise FileNotFoundError("installed Hermes binary or venv Python is missing")
        self.environment = dict(os.environ, HOME=str(home), HERMES_HOME=str(home / ".hermes"))
        for key in ("HERMES_BUNDLES_DIR", "HERMES_SKILLS_DIR", "HERMES_PROFILE"):
            self.environment.pop(key, None)

    def run(self, script, request):
        result = subprocess.run(
            [str(self.python), "-c", script], input=json.dumps(request), text=True,
            capture_output=True, cwd=self.install, env=self.environment,
        )
        if result.returncode:
            raise RuntimeError(f"native Hermes Python failed with exit {result.returncode}; no fallback")
        return json.loads(result.stdout)

    def inspect(self, files, bundles):
        return self.run(INSPECT, {"files": [str(f) for f in files], "bundles": str(bundles)})

    def configure(self, destination):
        for key, value in (("external_dirs", [str(destination)]), ("auto_load", [])):
            result = subprocess.run(
                [str(self.binary), "config", "set", f"skills.{key}", json.dumps(value)],
                text=True, capture_output=True, cwd=self.install, env=self.environment,
            )
            if result.returncode:
                raise RuntimeError(f"native Hermes config set skills.{key} failed with exit {result.returncode}")

    def discover(self, manifest):
        return self.run(DISCOVER, manifest)


def skill_files(root, excluded):
    files = []
    if not root.exists():
        return files
    for directory, dirs, names in os.walk(root):
        dirs[:] = sorted(d for d in dirs if d not in excluded)
        if "SKILL.md" in names:
            files.append(Path(directory) / "SKILL.md")
            dirs[:] = []
    return files


def read_profile(profile):
    manifest = json.loads((profile / "manifest.json").read_text())
    if set(manifest["automatic"]) != CORE:
        raise ValueError("Hermes profile requires exactly the three core skills")
    names = set()
    for entry in manifest["skills"]:
        name, relative = entry["name"], Path(entry["path"])
        if name in names or not name or "/" in name or name in {".", ".."}:
            raise ValueError("profile contains an invalid or duplicate skill name")
        if relative.is_absolute() or ".." in relative.parts:
            raise ValueError("profile skill path must stay inside the snapshot")
        if not (profile / relative / "SKILL.md").is_file():
            raise FileNotFoundError(profile / relative / "SKILL.md")
        names.add(name)
    if not CORE <= names:
        raise ValueError("profile core skills are missing")
    return manifest


def slugify(name):
    slug = re.sub(r"[^\w-]", "", name.lower().replace(" ", "-").replace("_", "-"))
    return re.sub(r"-{2,}", "-", slug).strip("-")


def bundle_command(name, identifier, description, namespace, occupied):
    slug = slugify(name)
    if not slug:
        raise ValueError("skill name has no native command slug")
    candidate, number = slug, 1
    while True:
        payload = {"name": candidate, "description": description, "skills": [identifier]}
        if candidate not in occupied or occupied[candidate] == payload:
            occupied[candidate] = payload
            return candidate, payload
        number += 1
        candidate = f"{namespace}-{slug}" if number == 2 else f"{namespace}-{slug}-{number - 1}"


def equal_directories(first, second):
    left = {str(p.relative_to(first)): p for p in first.rglob("*")}
    right = {str(p.relative_to(second)): p for p in second.rglob("*")}
    if left.keys() != right.keys():
        return False
    for relative, path in left.items():
        other = right[relative]
        if path.is_symlink() or other.is_symlink():
            if not path.is_symlink() or not other.is_symlink() or os.readlink(path) != os.readlink(other):
                return False
        elif path.is_dir() != other.is_dir():
            return False
        elif path.is_file() and not filecmp.cmp(path, other, shallow=False):
            return False
    return True


def link_directory(path, target):
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.is_symlink() and os.readlink(path) == str(target):
        return
    if path.exists() and not path.is_symlink():
        raise FileExistsError(f"refusing to replace original directory: {path}")
    temporary = path.with_name(f".{path.name}.{os.getpid()}")
    temporary.symlink_to(target, target_is_directory=True)
    temporary.replace(path)


def sync(profile, home, destination, hermes):
    profile, home, destination = profile.absolute(), home.absolute(), destination.absolute()
    policy = read_profile(profile)
    local = home / ".hermes/skills"
    archive = local / ".archive"
    bundles = home / ".hermes/skill-bundles"
    native = hermes.inspect([], bundles)
    visible = skill_files(local, set(native["excluded"]))
    archived = skill_files(archive, set(native["excluded"]) | {".previous"})
    sources = [profile / e["path"] / "SKILL.md" for e in policy["skills"]]
    metadata = hermes.inspect(sources + visible + archived, bundles)["skills"]
    moves = []
    native_core = {}
    for file in visible:
        name = metadata[str(file)]["name"]
        if name in CORE:
            native_core[name] = file.parent
        elif name != ESSENTIAL:
            target = archive / file.parent.relative_to(local)
            if target.exists() or target.is_symlink():
                if not equal_directories(file.parent, target):
                    raise FileExistsError(f"archive content differs, originals unchanged: {target}")
                duplicate = archive / ".previous" / file.parent.relative_to(local)
                number = 1
                while duplicate.with_name(f"{duplicate.name}.{number}").exists():
                    number += 1
                moves.append((file.parent, duplicate.with_name(f"{duplicate.name}.{number}")))
            else:
                moves.append((file.parent, target))
    links = {}
    commands = []
    occupied = {slug: row["data"] for slug, row in native["bundles"].items()}
    occupied.update({slug: None for slug in native["reserved"]})
    occupied.update({slugify(n): None for n in CORE | {ESSENTIAL}})
    for entry, file in zip(policy["skills"], sources):
        name = entry["name"]
        if metadata[str(file)]["name"] != name:
            raise ValueError(f"profile manifest name differs from SKILL.md: {name}")
        if name in CORE:
            links[f"core/{name}"] = str(native_core.get(name, file.parent))
            continue
        relative = f".archive/profile/{name}"
        links[relative] = str(file.parent)
        identifier = relative
        command, payload = bundle_command(name, identifier, metadata[str(file)]["description"], "profile", occupied)
        commands.append({"name": name, "command": command, "identifier": identifier, "source": str(file.parent),
                         "payload": payload})
    native_identifiers = set()
    for file in archived + visible:
        info = metadata[str(file)]
        if info["name"] in CORE | {ESSENTIAL}:
            continue
        source = archive / file.parent.relative_to(local) if file in visible else file.parent
        identifier = ".archive/" + str(source.relative_to(archive))
        if identifier in native_identifiers:
            continue
        native_identifiers.add(identifier)
        command, payload = bundle_command(info["name"], identifier, info["description"], "native", occupied)
        commands.append({"name": info["name"], "command": command, "identifier": identifier, "source": str(source),
                         "payload": payload})
    record = destination / "manifest.json"
    previous = json.loads(record.read_text()) if record.exists() else {"links": {}}
    for relative in set(previous["links"]) | set(links):
        path = destination / relative
        if path.exists() and not path.is_symlink():
            raise FileExistsError(f"refusing to replace original directory: {path}")
    for source, target in moves:
        target.parent.mkdir(parents=True, exist_ok=True)
        source.rename(target)
    for relative, target in links.items():
        link_directory(destination / relative, Path(target))
    for relative in set(previous["links"]) - set(links):
        path = destination / relative
        if path.is_symlink():
            path.unlink()
    bundles.mkdir(parents=True, exist_ok=True)
    for entry in commands:
        path = bundles / f'{entry["command"]}.yaml'
        content = json.dumps(entry["payload"], indent=2) + "\n"
        existing = native["bundles"].get(entry["command"])
        if existing:
            continue
        if path.exists() or path.is_symlink():
            raise FileExistsError(f"refusing to replace original bundle: {path}")
        path.write_text(content)
    manifest = {"core": sorted(CORE), "visible": sorted(CORE | ({ESSENTIAL} if any(
        metadata[str(f)]["name"] == ESSENTIAL for f in visible) else set())),
        "commands": commands, "links": links, "essential_exception": ESSENTIAL}
    destination.mkdir(parents=True, exist_ok=True)
    content = json.dumps(manifest, indent=2) + "\n"
    if not record.exists() or record.read_text() != content:
        record.write_text(content)
    hermes.configure(destination)
    return {"profile": str(destination), "archived": len(moves), "bundles": len(commands),
            "visible": manifest["visible"], "essential_exception": ESSENTIAL}


def verify(destination, hermes):
    manifest = json.loads((destination / "manifest.json").read_text())
    for relative, target in manifest["links"].items():
        path = destination / relative
        if not path.is_symlink() or path.resolve() != Path(target).resolve():
            raise ValueError(f"generated link differs: {path}")
    result = hermes.discover(manifest)
    if not result["verified"]:
        raise ValueError("; ".join(result["problems"]))
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("sync", "verify"))
    parser.add_argument("--profile", type=Path, required=True)
    parser.add_argument("--home", type=Path, default=Path.home())
    parser.add_argument("--destination", type=Path)
    parser.add_argument("--hermes", type=Path)
    args = parser.parse_args()
    destination = args.destination or args.profile.absolute().parent / "hermes"
    binary = args.hermes or args.home / ".local/share/mise/installs/http-hermes/latest/bin/hermes"
    try:
        hermes = Hermes(binary, args.home.absolute())
        result = sync(args.profile, args.home, destination, hermes) if args.command == "sync" else verify(destination, hermes)
    except (OSError, ValueError, RuntimeError, KeyError) as error:
        print(f"hermes-profile: {error}", file=sys.stderr)
        return 1
    print(json.dumps(result))
    return 0


if __name__ == "__main__":
    sys.exit(main())
