# Word movement is independent of the finder UI.

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

bindkey -M emacs '^[[1;5C' _zfh_forward_zword
bindkey -M emacs '^[[1;3D' _zfh_backward_word
bindkey -M emacs '^[b' _zfh_backward_word
bindkey -M emacs '^[[1;5D' _zfh_backward_zword
