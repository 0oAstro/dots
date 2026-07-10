[[ ${ZPROFRC:-0} == 1 ]] && zmodload zsh/zprof

# Pokemon greeting.
if [[ -t 0 && -t 1 && -z ${ZSH_EXECUTION_STRING:-} ]] && (( $+commands[pokeget] )); then
  () {
    setopt localoptions noprompt_sp noprompt_cr
    pokeget random --hide-name 2>/dev/null
    print
  }
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of .zshrc.
# Initialization code that may require console input must go above this block;
# everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Interactive shell entry point.

PROMPT_EOL_MARK=''


source "$ZDOTDIR/.zstyles"
source "$ZDOTDIR/lib/antidote.zsh"

source "$ZDOTDIR/config/core/options.zsh"
source "$ZDOTDIR/config/core/completions.zsh"

source "$ZDOTDIR/config/plugins/env.zsh"
source "$ZDOTDIR/config/plugins/load.zsh"
source "$ZDOTDIR/config/plugins/fzf.zsh"
source "$ZDOTDIR/config/plugins/zoxide.zsh"

source "$ZDOTDIR/lib/prompt.zsh"

source "$ZDOTDIR/config/integrations/macos.zsh"
source "$ZDOTDIR/config/integrations/linux.zsh"
source "$ZDOTDIR/config/integrations/age-secrets.zsh"
source "$ZDOTDIR/config/integrations/bitwarden.zsh"
source "$ZDOTDIR/config/integrations/terminal.zsh"
source "$ZDOTDIR/config/integrations/remote.zsh"
source "$ZDOTDIR/config/integrations/history-aux.zsh"

source "$ZDOTDIR/config/ui/aliases.zsh"
source "$ZDOTDIR/config/ui/functions.zsh"
source "$ZDOTDIR/config/ui/clipboard.zsh"
source "$ZDOTDIR/config/ui/editor.zsh"
source "$ZDOTDIR/config/ui/globalias.zsh"
source "$ZDOTDIR/config/ui/fzf-widgets.zsh"
source "$ZDOTDIR/config/ui/autosuggestions.zsh"

source "$ZDOTDIR/lib/recompile.zsh"

[[ ${ZPROFRC:-0} == 1 ]] && zprof

eval "$(zsh-patina activate)"
