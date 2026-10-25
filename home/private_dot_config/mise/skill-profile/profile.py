import argparse
import hashlib
import json
import os
import re
import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parent


def read_policy():
    return json.loads((ROOT / "profile.json").read_text())


def frontmatter(text):
    parts = text.split("---", 2)
    if len(parts) != 3 or parts[0].strip():
        raise ValueError("skill needs YAML frontmatter")
    return parts[1], parts[2]


def skill_name(text):
    header, _ = frontmatter(text)
    match = re.search(r"^name:\s*(.+)$", header, re.MULTILINE)
    if not match:
        raise ValueError("skill needs a name")
    return match.group(1).strip().strip("\"'")


def rewrite_skill(text, automatic):
    header, body = frontmatter(text)
    lines = []
    for line in header.strip().splitlines():
        if re.match(r"^(disable-model-invocation|user-invocable|paths):", line):
            continue
        lines.append(line)
    lines.append(f"disable-model-invocation: {str(not automatic).lower()}")
    lines.append("user-invocable: true")
    return "---\n" + "\n".join(lines) + "\n---" + body


def source_inventory(home, policy):
    installs = home / ".local/share/mise/installs"
    sources = []
    for entry in policy["sources"]:
        source = installs / entry["path"]
        if not source.exists():
            if entry.get("optional") or entry["name"] in {"intercom", "rea"}:
                continue
            raise FileNotFoundError(source)
        sources.append((entry, source.resolve()))
    record = home / ".claude/plugins/installed_plugins.json"
    if record.exists():
        plugins = json.loads(record.read_text()).get("plugins", {})
        rows = plugins.get("frontend-design@claude-plugins-official", [])
        if rows:
            source = Path(rows[0]["installPath"])
            if not source.exists():
                raise FileNotFoundError(source)
            sources.append(({"name": "frontend-design", "root": ".", "skills": "skills"}, source))
    return sources


def build_snapshot(staging, home, policy):
    automatic = set(policy["automatic"])
    removed = set(policy["removed"])
    entries = []
    for entry, source in source_inventory(home, policy):
        target = staging / entry["name"]
        shutil.copytree(source / entry["root"], target, ignore=shutil.ignore_patterns(".git", "node_modules", "__pycache__", "*.pyc"))
        for name in ("README.md", "LICENSE", "LICENSE.md"):
            if (source / name).is_file() and not (target / name).exists():
                shutil.copy2(source / name, target / name)
        skill_root = target / entry["skills"]
        selected = entry.get("include")
        for file in sorted(skill_root.rglob("SKILL.md")):
            text = file.read_text()
            name = skill_name(text)
            relative = str(file.parent.relative_to(skill_root))
            if name in removed or selected is not None and relative not in selected:
                file.unlink()
                continue
            file.write_text(rewrite_skill(text, name in automatic))
            entries.append({"name": name, "path": str(file.parent.relative_to(staging)), "automatic": name in automatic})
    names = [entry["name"] for entry in entries]
    if len(set(names)) != len(names):
        raise ValueError("duplicate skill names")
    if set(policy["automatic"]) - set(names):
        raise ValueError("automatic skills are missing")
    for name in ("emil", "matt"):
        plugin = staging / name / ".claude-plugin"
        plugin.mkdir()
        paths = [f"./{entry["path"].removeprefix(name + "/")}" for entry in entries if entry["path"].startswith(name + "/")]
        manifest = {"name": name, "skills": paths}
        (plugin / "plugin.json").write_text(json.dumps(manifest) + "\n")
    flat = staging / "skills"
    flat.mkdir()
    for entry in entries:
        (flat / entry["name"]).symlink_to(Path("..") / entry["path"])
    manifest = {"automatic": policy["automatic"], "removed": policy["removed"], "skills": entries}
    (staging / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    return manifest


def snapshot_digest(path):
    digest = hashlib.sha256()
    for file in sorted(path.rglob("*")):
        relative = str(file.relative_to(path))
        if file.is_symlink():
            digest.update(relative.encode())
            digest.update(os.readlink(file).encode())
        elif file.is_file():
            digest.update(relative.encode())
            digest.update(file.read_bytes())
    return digest.hexdigest()


def sync(home, destination, policy):
    destination.mkdir(parents=True, exist_ok=True)
    staging = destination / f".staging-{os.getpid()}"
    try:
        manifest = build_snapshot(staging, home, policy)
        digest = snapshot_digest(staging)
        snapshot = destination / "snapshots" / digest
        snapshot.parent.mkdir(exist_ok=True)
        if snapshot.exists():
            shutil.rmtree(staging)
        else:
            staging.rename(snapshot)
        temporary = destination / f".current-{os.getpid()}"
        temporary.symlink_to(Path("snapshots") / digest)
        temporary.replace(destination / "current")
        print(json.dumps({"profile": str(destination / "current"), "automatic": manifest["automatic"], "registered": len(manifest["skills"]), "snapshot": digest}))
    finally:
        if staging.exists():
            shutil.rmtree(staging)


def verify(destination, policy):
    profile = destination / "current"
    manifest = json.loads((profile / "manifest.json").read_text())
    automatic = set()
    names = set()
    for entry in manifest["skills"]:
        file = profile / entry["path"] / "SKILL.md"
        text = file.read_text()
        header, _ = frontmatter(text)
        name = skill_name(text)
        names.add(name)
        if "disable-model-invocation: false" in header:
            automatic.add(name)
        assert "user-invocable: true" in header, file
        assert (profile / "skills" / name).resolve() == file.parent.resolve(), name
        assert not re.search(r"^paths:", header, re.MULTILINE), file
    assert automatic == set(policy["automatic"]), automatic
    assert not names.intersection(policy["removed"]), names
    assert (profile / "pstack/plugins/pstack/skills/setup-pstack/scripts/read-sheet.sh").exists()
    print(json.dumps({"automatic": sorted(automatic), "registered": len(names), "removed": policy["removed"], "verified": True}))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["sync", "verify"])
    parser.add_argument("--home", type=Path, default=Path.home())
    parser.add_argument("--destination", type=Path, default=ROOT)
    args = parser.parse_args()
    policy = read_policy()
    if args.command == "sync":
        sync(args.home, args.destination, policy)
    else:
        verify(args.destination, policy)


if __name__ == "__main__":
    main()
