# The installed fzf owns its widgets, including after an upgrade.
(( $+commands[fzf] )) || return 0
# Instant prompt can redirect stdin; the execution-string guard still keeps
# widget initialization out of noninteractive command/benchmark shells.
[[ -z ${ZSH_EXECUTION_STRING:-} ]] || return 0
_zdots_source_generated fzf --zsh

# Keep fzf's ** trigger; Aloxaf supplies the ordinary Tab selector.
local -a selectors=( ${^fpath}/fzf-tab.plugin.zsh(N) )
if (( $#selectors )); then
  source "$selectors[1]"

  # compadd -A doubles backslashes in pre-quoted, non-file (-Q without -f)
  # candidates. Undo that transport escaping (e.g. Carapace's output).
  # Update both the source function and the copy installed by enable-fzf-tab.
  local before='local ret=$?'
  local after=$before$'\n''[[ ${_opts[(r)-Q]} != -Q || $#isfile != 0 ]] || __hits=( "${(@)__hits//\\\\/\\}" )'
  functions[-ftb-compadd]=${functions[-ftb-compadd]/$before/$after}
  functions[compadd]=$functions[-ftb-compadd]
fi

# A fixed pane-relative height also avoids the selector's cursor-query loop
# in terminals/multiplexers that do not answer DSR requests.
typeset -g FZF_TMUX_HEIGHT=${FZF_TMUX_HEIGHT:-40%}
unset selectors before after
