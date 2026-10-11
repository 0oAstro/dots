#!/bin/sh
set -eu

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')
backup='(\.bak|\.orig|-backup)(\b|$)|(^|[/[:space:]])backups?(/|$)'

targets=""
case "$tool" in
  Write|Edit|MultiEdit|NotebookEdit)
    targets=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
    ;;
  apply_patch)
    targets=$(printf '%s' "$input" | jq -r '.tool_input | .. | strings' | sed -n -E 's/^\*\*\* (Add File|Update File|Move to): //p')
    ;;
  Bash)
    command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
    targets=$(printf '%s\n' "$command" | grep -E -o "(\b(cp|mv|rsync|ditto|install|tee)\b[^;&|]*|>>?[[:space:]]*[^[:space:];&|]+|sed[[:space:]]+-i[.][[:alnum:]]+)" || true)
    ;;
esac

if printf '%s\n' "$targets" | grep -E -q "$backup|sed[[:space:]]+-i[.]"; then
  echo "Edit the file in place. Git and the service's own export keep the history (see ~/.local/share/chezmoi/home/.me/AGENTS.md)." >&2
  exit 2
fi
exit 0
