# The installed fzf owns its widgets, including after an upgrade.
(( $+commands[fzf] )) || return 0
# Instant prompt can redirect stdin; the execution-string guard still keeps
# widget initialization out of noninteractive command/benchmark shells.
[[ -z ${ZSH_EXECUTION_STRING:-} ]] || return 0
_zdots_source_generated fzf --zsh

# Keep fzf's ** trigger; the pinned fzf-tab dependency supplies ordinary Tab.
local -a selectors=( ${^fpath}/fzf-tab.plugin.zsh(N) )
if (( $#selectors )); then
  source "$selectors[1]"
fi

# A fixed pane-relative height also avoids the selector's cursor-query loop
# in terminals/multiplexers that do not answer DSR requests.
typeset -g FZF_TMUX_HEIGHT=${FZF_TMUX_HEIGHT:-40%}
unset selectors
