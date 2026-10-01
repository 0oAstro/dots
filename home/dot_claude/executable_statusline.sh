#!/usr/bin/env bash
# Mirrors the Codex status line: model+effort, dir, host, branch, context left, cost.
in=$(cat)
j() { jq -r "$1 // empty" <<<"$in"; }

model=$(j '.model.display_name')
effort=$(jq -r '.effortLevel // empty' ~/.claude/settings.json 2>/dev/null)
dir=$(j '.workspace.current_dir')
dir=${dir/#$HOME/\~}
branch=$(git -C "$(j '.workspace.current_dir')" branch --show-current 2>/dev/null)
used=$(j '.context_window.used_percentage')
cost=$(j '.cost.total_cost_usd')

c() { printf '\033[%sm%s\033[0m' "$1" "$2"; }
out="$(c '1;35' "$model${effort:+ ($effort)}") $(c 36 "$dir") $(c 2 "@$(hostname -s)")"
[ -n "$branch" ] && out+=" $(c 32 "⎇ $branch")"
if [ -n "$used" ]; then
  left=$((100 - ${used%.*}))
  col=32
  [ $left -lt 40 ] && col=33
  [ $left -lt 15 ] && col=31
  out+=" $(c $col "${left}% ctx")"
fi
[ -n "$cost" ] && out+=" $(c 2 "$(printf '$%.2f' "$cost")")"
printf '%s' "$out"
