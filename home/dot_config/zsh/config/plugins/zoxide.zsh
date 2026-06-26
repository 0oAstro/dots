# Lazy zoxide init keeps startup cheap while preserving `z`, `zi`, and `cd`.
#

function z()      { unfunction z zoxide zi; eval "$(zoxide init zsh)"; z "$@"; }
function zoxide() { unfunction z zoxide zi; eval "$(zoxide init zsh)"; zoxide "$@"; }
function zi()     { unfunction z zoxide zi; eval "$(zoxide init zsh)"; zi "$@"; }
alias cd=z
