# Not `-t 0`: instant prompt can redirect stdin. Keeps widgets out of `zsh -c`.
[[ -z ${ZSH_EXECUTION_STRING:-} ]] || return 0
_zdots_source_generated fzf --zsh

# Keep fzf's ** trigger; the pinned fzf-tab dependency supplies ordinary Tab.
local -a selectors=( ${^fpath}/fzf-tab.plugin.zsh(N) )
if (( $#selectors )); then
  source "$selectors[1]"
fi

# A fixed height skips fzf's cursor query, which loops in terminals and
# multiplexers that do not answer DSR requests.
typeset -g FZF_TMUX_HEIGHT=${FZF_TMUX_HEIGHT:-40%}
unset selectors
