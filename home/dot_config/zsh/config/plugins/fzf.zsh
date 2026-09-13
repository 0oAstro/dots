# The installed fzf owns its widgets, including after an upgrade.
(( $+commands[fzf] )) || return 0
# Instant prompt can redirect stdin; the execution-string guard still keeps
# widget initialization out of noninteractive command/benchmark shells.
[[ -z ${ZSH_EXECUTION_STRING:-} ]] || return 0
_zdots_source_generated fzf --zsh

# Keep fzf's ** trigger; delegate ordinary Tab to the alternative selector.
local -a selectors=( ${^fpath}/fzf-zsh-completion.sh(N) )
if (( $#selectors )); then
  source "$selectors[1]"

  # Upstream passes `-W interactive` to awk, which Apple awk treats as a
  # filename. The script already flushes with system(""); this flag is optional.
  if [[ $OSTYPE == darwin* && $_fzf_bash_completion_awk == awk ]]; then
    _zdots_completion_awk() {
      [[ $1 == -W && $2 == interactive ]] && shift 2
      command awk "$@"
    }
    _fzf_bash_completion_awk=_zdots_completion_awk
  fi

  # compadd -A doubles backslashes in pre-quoted, non-file (-Q without -f)
  # candidates. Undo that transport escaping (e.g. Carapace's output).
  # Keep the upstream implementation; only correct this compatibility edge.
  local before='local __code="$?"'
  local after=$before$'\n''[[ -z $__noquote || -n $__filenames ]] || __hits=( "${(@)__hits//\\\\/\\}" )'
  functions[_fzf_completion_compadd]=${functions[_fzf_completion_compadd]/$before/$after}

  # Apple grep spends ~0.5s matching thousands of exact function names here,
  # twice per Tab. Zsh can subtract the same name sets without a grep process.
  _zdots_completion_loaded_functions() {
    local -a names=( ${(k)functions} )
    local -a excluded=( ${(f)"$(functions -u +)"} ${(f)1} )
    names=( ${names:|excluded} )
    (( $#names )) && print -rl -- "${names[@]}"
    return 0
  }
  before='functions + | "$_fzf_bash_completion_grep" -F -vx -e "$(functions -u +)"'
  after='_zdots_completion_loaded_functions'
  functions[_fzf_completion]=${functions[_fzf_completion]/$before/$after}
  before='functions + | "$_fzf_bash_completion_grep"  -F -vx -e "$(functions -u +)" -e "$__full_functions"'
  after='_zdots_completion_loaded_functions "$__full_functions"'
  functions[_fzf_completion]=${functions[_fzf_completion]/$before/$after}
  # The variable snapshot has the same large fixed-pattern grep problem.
  # A hash lookup preserves whole-line exclusion, including literal escapes.
  _zdots_completion_variable_delta() {
    command awk 'FILENAME == ARGV[1] { excluded[$0]; next } !($0 in excluded)' "$1" -
  }
  before='"$_fzf_bash_completion_grep" -xvFf'
  after='_zdots_completion_variable_delta'
  functions[_fzf_completion]=${functions[_fzf_completion]/$before/$after}
  unset before after
fi

# A fixed pane-relative height also avoids the selector's cursor-query loop
# in terminals/multiplexers that do not answer DSR requests.
typeset -g FZF_TMUX_HEIGHT=${FZF_TMUX_HEIGHT:-40%}
unset selectors
