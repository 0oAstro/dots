#!/usr/bin/env python3
"""Format the repo's shell scripts with shfmt, including chezmoi templates.

shfmt cannot parse `{{ ... }}`, so each template action is swapped for a
placeholder word, formatted, and swapped back. Style comes from .editorconfig.

Usage: tests/fmt.py           rewrite files in place
       tests/fmt.py --check   list unformatted files and exit 1
"""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ACTION = re.compile(r"\{\{.*?\}\}")
PLAIN = ["install.sh", "tests/*.sh", "home/**/*.sh", "home/**/*.bash",
         "home/private_dot_config/zsh/bin/executable_fzf-preview"]


def scripts():
    seen = set()
    for pattern in PLAIN + ["home/.chezmoiscripts/*.sh.tmpl"]:
        for path in sorted(ROOT.glob(pattern)):
            if path.is_file() and path not in seen:
                seen.add(path)
                yield path


def shfmt(text, path):
    actions = []

    def mask(match):
        actions.append(match.group(0))
        return f"__TPL{len(actions) - 1}__"

    masked = ACTION.sub(mask, text)
    name = str(path.relative_to(ROOT)).removesuffix(".tmpl")
    out = subprocess.run(["shfmt", "--filename", name], input=masked,
                         capture_output=True, text=True, cwd=ROOT)
    if out.returncode:
        sys.exit(f"{path.relative_to(ROOT)}: {out.stderr.strip()}")
    return re.sub(r"__TPL(\d+)__", lambda m: actions[int(m.group(1))], out.stdout)


def main():
    check = "--check" in sys.argv[1:]
    dirty = []
    for path in scripts():
        text = path.read_text()
        formatted = shfmt(text, path)
        if formatted != text:
            dirty.append(str(path.relative_to(ROOT)))
            if not check:
                path.write_text(formatted)
    for name in dirty:
        print(("unformatted: " if check else "formatted: ") + name)
    return 1 if check and dirty else 0


if __name__ == "__main__":
    sys.exit(main())
