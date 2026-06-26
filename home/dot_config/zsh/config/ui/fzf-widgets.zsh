# zsh4humans-inspired fzf/history/directory widgets.

_zfh_accept_autosuggest_full() {
  if (( $+widgets[autosuggest-accept] )) && [[ -n $POSTDISPLAY ]]; then
    zle autosuggest-accept
  else
    zle end-of-line
  fi
}
zle -N _zfh_accept_autosuggest_full

_zfh_accept_autosuggest_word() {
  emulate -L zsh -o extended_glob
  if [[ -n $POSTDISPLAY ]]; then
    local rest=$POSTDISPLAY take
    if [[ $rest == [[:space:]]##* ]]; then
      take=${${rest%%[^[:space:]]*}:-$rest}
      rest=${rest#$take}
    fi
    if [[ -n $rest ]]; then
      local wordchars=${WORDCHARS//[[:space:][:alnum:]]}
      if [[ $rest == [[:alnum:]$wordchars]##* ]]; then
        take+=${rest%%[^[:alnum:]$wordchars]*}
      else
        take+=${rest[1]}
      fi
    fi
    [[ -n $take ]] || take=${POSTDISPLAY[1]}
    BUFFER+=$take
    POSTDISPLAY=${POSTDISPLAY#$take}
    CURSOR=${#BUFFER}
    zle .reset-prompt
  else
    zle _zfh_forward_word
  fi
}
zle -N _zfh_accept_autosuggest_word

_zfh_forward_word() {
  emulate -L zsh -o extended_glob
  local buf w=${WORDCHARS//[[:space:][:alnum:]]}
  repeat ${NUMERIC:-1}; do
    buf=${RBUFFER##[[:space:]]#}
    if (( $#buf < 2 )); then
      buf=
    elif [[ $buf == ?[[:space:]]* ]]; then
      buf[1]=
    elif [[ $buf[1,2] != *[[:alnum:]$w]* ]]; then
      buf=${buf##[^[:space:][:alnum:]$w]#}
    else
      [[ $buf == [[:alnum:]$w]* ]] || buf[1]=
      buf=${buf##[[:alnum:]$w]#}
    fi
    (( CURSOR += $#RBUFFER - $#buf ))
  done
}
zle -N _zfh_forward_word

_zfh_backward_word() {
  emulate -L zsh -o extended_glob
  local buf w=${WORDCHARS//[[:space:][:alnum:]]}
  repeat ${NUMERIC:-1}; do
    buf=${LBUFFER%%[[:space:]]#}
    if (( $#buf < 2 )); then
      buf=
    elif [[ $buf == *[[:space:]]? ]]; then
      buf[-1]=
    elif [[ $buf[-2,-1] != *[[:alnum:]$w]* ]]; then
      buf=${buf%%[^[:space:][:alnum:]$w]#}
    else
      [[ $buf == *[[:alnum:]$w] ]] || buf[-1]=
      buf=${buf%%[[:alnum:]$w]#}
    fi
    (( CURSOR -= $#LBUFFER - $#buf ))
  done
}
zle -N _zfh_backward_word

_zfh_forward_zword() {
  emulate -L zsh
  local word buf
  repeat ${NUMERIC:-1}; do
    buf=$PREBUFFER$BUFFER
    for word in ${(Z:n:)buf} ''; do
      (( $#buf < $#RBUFFER )) && break
      buf=${${buf##[[:space:]]#}:$#word}
    done
    CURSOR=$(($#BUFFER - $#buf))
    (( CURSOR > $#BUFFER )) && CURSOR=$#BUFFER
  done
}
zle -N _zfh_forward_zword

_zfh_backward_zword() {
  emulate -L zsh
  local word buf tail
  repeat ${NUMERIC:-1}; do
    buf=$PREBUFFER$BUFFER
    for word in '' ${(Z:n:)buf}; do
      tail=${${buf:$#word}##[[:space:]]#}
      (( $#tail <= $#RBUFFER )) && break
      buf=$tail
    done
    CURSOR=$(($#buf <= $#BUFFER ? $#BUFFER - $#buf : 0))
  done
}
zle -N _zfh_backward_zword

_zfh_fzf_history() {
  local selected
  selected=$(fc -rl 1 2>/dev/null | awk '{$1=""; sub(/^ /,""); if (!seen[$0]++) print}' |
    FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-} --height=80% --layout=reverse --border --no-multi --exact --cycle --bind=ctrl-u:clear-query,ctrl-k:kill-line,alt-j:clear-query" \
    fzf --query="$LBUFFER" --preview 'printf %s {}' --preview-window=wrap:3:down:noborder) || return
  BUFFER=$selected
  CURSOR=${#BUFFER}
  zle -R
}
zle -N _zfh_fzf_history

_zfh_fzf_dir_history() {
  local selected
  selected=$(zoxide query -l 2>/dev/null | awk 'NF && !seen[$0]++' |
    FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-} --height=80% --layout=reverse --border --no-multi --exact --cycle --bind=tab:down,btab:up,ctrl-u:clear-query" \
    fzf --preview 'eza -la --color=always {}' --preview-window=right:50%) || return
  cd -- "$selected" || return
  zle reset-prompt
}
zle -N _zfh_fzf_dir_history

_zdots_fzf_cd_down() {
  setopt local_options no_aliases pipefail
  local dir
  dir=$(fd --type d --hidden --exclude .git --color=never . |
    sed 's#^./##' |
    fzf --height ${FZF_TMUX_HEIGHT:-40%} --reverse --scheme=path)
  [[ -n $dir ]] || return
  BUFFER="cd ${(q)dir}"
  zle accept-line
}
zle -N _zdots_fzf_cd_down

bindkey -M emacs '^[[1;5C' _zfh_forward_zword
bindkey -M emacs '^[[1;3D' _zfh_backward_word
bindkey -M emacs '^[b' _zfh_backward_word
bindkey -M emacs '^[[1;5D' _zfh_backward_zword
bindkey -M emacs '^R' _zfh_fzf_history
bindkey -M emacs '^[r' _zfh_fzf_dir_history
bindkey -M emacs '^[c' _zdots_fzf_cd_down
