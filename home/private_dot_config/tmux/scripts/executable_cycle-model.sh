#!/bin/bash
# tmux wrapper: cycle hermes model and send /model command to current pane
# Called from tmux keybinding via run-shell
# Pass --back to go backward, nothing for forward

DIRECTION="${1:-}"

MODEL=$(~/.local/bin/cycle-model $DIRECTION)

# Target the current session's active pane
TARGET=$(tmux display-message -p "#{session_name}:#{window_index}.#{pane_index}")
tmux send-keys -t "$TARGET" "/model $MODEL" Enter
