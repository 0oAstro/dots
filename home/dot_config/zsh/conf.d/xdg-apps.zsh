# ── xdg-apps — XDG compliance for common tools ──────────────────
# Adapted from mattmc3/zsh_custom

export INPUTRC="${INPUTRC:-$XDG_CONFIG_HOME/readline/inputrc}"
export GNUPGHOME="${GNUPGHOME:-$XDG_DATA_HOME/gnupg}"
[[ -e $GNUPGHOME ]] || mkdir -p $GNUPGHOME
alias gpg="${aliases[gpg]:-gpg} --homedir \"\$GNUPGHOME\""
