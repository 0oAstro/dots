#!/usr/bin/env bash
# Render every profile into scratch homes and check the result parses.
# Needs no age key: encrypted files are skipped. Usage: tests/render.sh [--smoke]
#   --smoke  also start an interactive zsh in the native profile's home.
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
# zsh can leave a background job writing into the scratch home for a moment.
cleanup() { rm -rf "$work" 2>/dev/null || {
  sleep 2
  rm -rf "$work"
} || true; }
trap cleanup EXIT
fail=0
# name|os|arch|switches json
profiles=(
  'aardvark|linux|arm64|"server":true,"harnesses":["claude","cursor","hermes","pi","prime"]'
  'thunderchief|darwin|arm64|"server":false,"harnesses":["claude","hermes","pi"],"modules":["ai_off","apps_comms","apps_dev","apps_media","dropbox","finder","games","google_drive","input","look","perf","vendor_updaters_off"]'
  'newbox|linux|amd64|"server":false,"harnesses":[]'
  'newmac|darwin|arm64|"server":true,"harnesses":["cursor","prime"]'
)

check() { # label command...
  local label=$1
  shift
  if ! out=$("$@" 2>&1); then
    printf '  FAIL %s\n%s\n' "$label" "$out" | sed 's/^/  /'
    fail=1
  fi
}

# chezmoi ignores unknown config keys, so check the age setting by name: without
# it, decrypting needs an age binary that a fresh machine does not have yet.
if ! chezmoi execute-template --init --promptBool server=false --promptString harnesses=pi \
  <"$repo/home/.chezmoi.toml.tmpl" | grep -qx 'useBuiltinAge = true'; then
  echo "FAIL .chezmoi.toml.tmpl must set useBuiltinAge = true"
  fail=1
fi

for p in "${profiles[@]}"; do
  IFS='|' read -r host os arch switches <<<"$p"
  home=$work/$host
  mkdir -p "$home"
  printf '%s\n' "{\"chezmoi\":{\"os\":\"$os\",\"arch\":\"$arch\",\"homeDir\":\"$home\",\"hostname\":\"$host\"},
    \"host\":\"$host\",$switches}" >"$work/$host.json"
  printf '[diff]\n  pager = "cat"\n' >"$work/$host.toml"
  cz=(chezmoi --source "$repo/home" --destination "$home" --config "$work/$host.toml"
    --override-data-file "$work/$host.json" --no-tty --keep-going)
  echo "== $host ($os/$arch)"
  check "apply" "${cz[@]}" apply --exclude scripts,encrypted,externals

  # Rendered scripts must be valid shell for the interpreter they name.
  while IFS= read -r script; do
    rendered=$work/$host.script
    if ! "${cz[@]}" execute-template <"$script" >"$rendered" 2>"$work/err"; then
      printf '  FAIL render %s\n' "${script##*/}"
      sed 's/^/    /' "$work/err"
      fail=1
      continue
    fi
    grep -q '[^[:space:]]' "$rendered" || continue # chezmoi skips empty scripts
    shell=$(head -1 "$rendered" | sed -E 's|^#!(/usr/bin/env )?||; s| .*||')
    check "${script##*/}" "${shell##*/}" -n "$rendered"
  done < <(find "$repo/home/.chezmoiscripts" -type f)

  # mise's GitHub credential must not go through a shim: the shim runs mise,
  # which needs that credential, so a cold cache forks without limit.
  if grep -q 'credential_command.*shims' "$home/.config/mise/config.toml"; then
    echo "  FAIL mise credential_command uses a shim"
    fail=1
  fi

  if [[ -f $home/.config/mise/conf.d/harness-pi.toml ]]; then
    check "Pi packages are mise-managed" python3 - "$home" "$("${cz[@]}" execute-template <"$repo/home/.chezmoiremove")" <<'PY'
import json
import pathlib
import re
import sys
import tomllib

home = pathlib.Path(sys.argv[1])
tools = tomllib.loads((home / ".config/mise/conf.d/harness-pi.toml").read_text())["tools"]
settings = json.loads((home / ".pi/agent/settings.json").read_text())
package = tools["npm:@cahalane/pi-monitor"]
assert package["version"] == "latest", package
assert "~/.local/share/mise/installs/npm-cahalane-pi-monitor/latest/lib/node_modules/@cahalane/pi-monitor" in settings["packages"], settings["packages"]
assert {"source": "~/.local/share/mise/installs/http-pstack/latest", "skills": []} in settings["packages"], settings["packages"]
assert "http:mattpocock-skills" in tools, tools.keys()
for skill in settings["skills"]:
    assert skill.startswith("~/.local/share/mise/installs/skill-profile/latest/current/"), skill
package = tools["npm:@sting8k/pi-vcc"]
assert package["version"] == "latest", package
assert package["npm_args"] == "--legacy-peer-deps", package
assert "~/.local/share/mise/installs/npm-sting8k-pi-vcc/latest/lib/node_modules/@sting8k/pi-vcc" in settings["packages"], settings["packages"]
assert "npm:@sting8k/pi-vcc" not in settings["packages"], settings["packages"]
assert settings["compaction"]["enabled"] is True, settings["compaction"]
assert {"source": "~/.local/share/mise/installs/npm-pi-intercom/latest/lib/node_modules/pi-intercom", "skills": []} in settings["packages"], settings["packages"]
assert settings["firecrawl-web"]["fetchModel"] == "bifrost/azure/gpt-6-luna", settings["firecrawl-web"]
extension_config = tomllib.loads((home / ".config/mise/conf.d/pi-global-tools.toml").read_text())
version = extension_config["tools"]["pi-global-tools"]["version"]
assert re.fullmatch(r"[0-9a-f]{64}", version), version
assert extension_config["plugins"]["pi-global-tools"] == str(home / ".pi/agent/package-sources/pi-global-tools"), extension_config
assert f"~/.local/share/mise/installs/pi-global-tools/{version}" in settings["packages"], settings["packages"]
remove_targets = set(sys.argv[2].splitlines())
assert ".pi/agent/skills" in remove_targets, remove_targets
assert ".pi/agent/extensions/codemode-gpt.ts" in remove_targets, remove_targets
assert ".pi/agent/extensions/firecrawl-web" in remove_targets, remove_targets
config = tomllib.loads((home / ".config/mise/config.toml").read_text())
assert "pi-global-tools" in config["settings"]["minimum_release_age_excludes"], config["settings"]
assert "pi-dev-extensions" in config["settings"]["minimum_release_age_excludes"], config["settings"]
vcc = json.loads((home / ".pi/agent/pi-vcc-config.json").read_text())
assert vcc["overrideDefaultCompaction"] is True, vcc
assert vcc["skipForProviders"] == [], vcc
assert ".pi/agent/pi-vcc-config.json" not in sys.argv[2].splitlines(), sys.argv[2]
PY
  fi

  while IFS= read -r f; do
    case $f in
      *.toml) check "${f#"$home"/}" python3 -c 'import sys,tomllib; tomllib.load(open(sys.argv[1],"rb"))' "$f" ;;
      */zed/settings.json) ;; # JSON with comments
      *.json) check "${f#"$home"/}" python3 -m json.tool "$f" ;;
      *.zsh | */.zshrc | */.zshenv | */.zprofile | */.zstyles) check "${f#"$home"/}" zsh -n "$f" ;;
      *.bash | */.bashrc | */.bash_profile) check "${f#"$home"/}" bash -n "$f" ;;
      *.sh) check "${f#"$home"/}" bash -n "$f" ;;
    esac
  done < <(find "$home" -type f)
  echo "   $(find "$home" -type f | wc -l | tr -d ' ') files"
done

if [[ ${1:-} == --smoke ]]; then
  native=$([[ $(uname) == Darwin ]] && echo newmac || echo newbox)
  echo "== zsh startup ($native)"
  (cd "$work" && env -i HOME="$work/$native" TERM=xterm-256color PATH="$PATH" \
    zsh -i -c 'print -r -- "zsh ok: $ZDOTDIR"; (( $+functions[edit-secrets] ))') || fail=1
fi

exit $fail
