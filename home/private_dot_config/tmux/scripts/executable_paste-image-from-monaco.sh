#!/usr/bin/env bash
set -euo pipefail

REMOTE_HOST="${TMUX_PASTE_IMAGE_REMOTE:-monaco}"
SAVE_DIR="${TMUX_PASTE_IMAGE_DIR:-$HOME/.cache/tmux-paste-image}"
mkdir -p "$SAVE_DIR"

filename="image_$(date +%Y-%m-%d_%H-%M-%S).png"
file_path="$SAVE_DIR/$filename"

remote_cmd='tmp=$(mktemp -t tmux-paste-image.XXXXXX.png) || exit 1
trap '\''rm -f "$tmp"'\'' EXIT
if command -v pngpaste >/dev/null 2>&1; then
  pngpaste "$tmp" >/dev/null 2>&1 || exit 2
elif [ -x /opt/homebrew/bin/pngpaste ]; then
  /opt/homebrew/bin/pngpaste "$tmp" >/dev/null 2>&1 || exit 2
else
  exit 127
fi
cat "$tmp"'

if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$REMOTE_HOST" "$remote_cmd" > "$file_path"; then
  rm -f "$file_path"
  tmux display-message "[paste-image] No PNG image in $REMOTE_HOST clipboard, or pngpaste/ssh failed"
  exit 1
fi

if [ ! -s "$file_path" ]; then
  rm -f "$file_path"
  tmux display-message "[paste-image] No PNG image in $REMOTE_HOST clipboard"
  exit 1
fi

if ! head -c 8 "$file_path" | LC_ALL=C grep -q $'^\x89PNG\r\n\x1a\n'; then
  rm -f "$file_path"
  tmux display-message "[paste-image] Clipboard data from $REMOTE_HOST was not a PNG"
  exit 1
fi

quoted_path=$(printf "%q" "$file_path")
tmux send-keys -t "${TMUX_PANE:-}" "$quoted_path"
tmux display-message "[paste-image] Pasted image path: $file_path"
