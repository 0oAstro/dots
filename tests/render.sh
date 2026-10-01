#!/usr/bin/env bash
# Render every profile into scratch homes and check the result parses.
# Needs no age key: encrypted files are skipped. Usage: tests/render.sh [--smoke]
#   --smoke  also start an interactive zsh in the native profile's home.
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fail=0
all='"ai":true,"cloud":true,"docker":true,"db":true,"sync":true'

# name|os|arch|modules json (the rest of a profile is shared)
profiles=(
  "aardvark|linux|arm64|{$all,\"ml\":true,\"media\":false,\"apple\":false,\"gui\":false,\"server\":true}"
  "thunderchief|darwin|arm64|{$all,\"ml\":false,\"media\":true,\"apple\":true,\"gui\":true,\"server\":false}"
  "newbox|linux|amd64|{\"ai\":false,\"cloud\":false,\"docker\":false,\"db\":false,\"sync\":false,\"ml\":false,\"media\":false,\"apple\":false,\"gui\":false,\"server\":false}"
  "newmac|darwin|arm64|{$all,\"ml\":true,\"media\":true,\"apple\":true,\"gui\":true,\"server\":true}"
)

check() { # label command...
  local label=$1; shift
  if ! out=$("$@" 2>&1); then
    printf '  FAIL %s\n%s\n' "$label" "$out" | sed 's/^/  /'
    fail=1
  fi
}

for p in "${profiles[@]}"; do
  IFS='|' read -r host os arch modules <<<"$p"
  home=$work/$host
  mkdir -p "$home"
  printf '%s\n' "{\"chezmoi\":{\"os\":\"$os\",\"arch\":\"$arch\",\"homeDir\":\"$home\",\"hostname\":\"$host\"},
    \"host\":\"$host\",\"modules\":$modules,\"git\":{\"signingKey\":\"~/.ssh/id_ed25519\"}}" >"$work/$host.json"
  printf '[diff]\n  pager = "cat"\n' >"$work/$host.toml"
  cz=(chezmoi --source "$repo/home" --destination "$home" --config "$work/$host.toml"
      --override-data-file "$work/$host.json" --no-tty --keep-going)
  echo "== $host ($os/$arch)"
  check "apply" "${cz[@]}" apply --exclude scripts,encrypted,externals

  # Rendered scripts must be valid shell for the interpreter they name.
  while IFS= read -r script; do
    rendered=$work/$host.script
    if ! "${cz[@]}" execute-template <"$script" >"$rendered" 2>"$work/err"; then
      printf '  FAIL render %s\n' "${script##*/}"; sed 's/^/    /' "$work/err"; fail=1; continue
    fi
    grep -q '[^[:space:]]' "$rendered" || continue # chezmoi skips empty scripts
    shell=$(head -1 "$rendered" | sed -E 's|^#!(/usr/bin/env )?||; s| .*||')
    check "${script##*/}" "${shell##*/}" -n "$rendered"
  done < <(find "$repo/home/.chezmoiscripts" -type f)

  while IFS= read -r f; do
    case $f in
      *.toml) check "${f#"$home"/}" python3 -c 'import sys,tomllib; tomllib.load(open(sys.argv[1],"rb"))' "$f" ;;
      */zed/settings.json) ;; # JSON with comments
      *.json) check "${f#"$home"/}" python3 -m json.tool "$f" ;;
      *.zsh|*/.zshrc|*/.zshenv|*/.zprofile|*/.zstyles) check "${f#"$home"/}" zsh -n "$f" ;;
      *.bash|*/.bashrc|*/.bash_profile) check "${f#"$home"/}" bash -n "$f" ;;
      *.sh) check "${f#"$home"/}" bash -n "$f" ;;
    esac
  done < <(find "$home" -type f)
  echo "   $(find "$home" -type f | wc -l | tr -d ' ') files"
done

if [[ ${1:-} == --smoke ]]; then
  native=$( [[ $(uname) == Darwin ]] && echo newmac || echo newbox )
  echo "== zsh startup ($native)"
  (cd "$work" && env -i HOME="$work/$native" TERM=xterm-256color PATH="$PATH" \
    zsh -i -c 'print -r -- "zsh ok: $ZDOTDIR"; (( $+functions[edit-secrets] ))') || fail=1
fi

exit $fail
