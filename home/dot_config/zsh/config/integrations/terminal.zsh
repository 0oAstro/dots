# Terminal and terminfo helpers.

zmodload zsh/terminfo
[[ ${terminfo[Tc]:-} == yes && -z ${COLORTERM:-} ]] && export COLORTERM=truecolor
