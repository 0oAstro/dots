[[ ${ZPROFRC:-0} == 1 ]] && zmodload zsh/zprof

if [[ ${HERDR_ENV:-} == 1 && -t 1 ]]; then
  unset NO_COLOR
  export COLORTERM=truecolor
fi

if [[ -z ${ZSH_EXECUTION_STRING:-} ]]; then
  () {
    setopt localoptions noprompt_sp noprompt_cr
    local pokemon=$XDG_DATA_HOME/mise/installs/cargo-pokeget/latest/bin/pokeget
    [[ -x $pokemon ]] || pokemon=${commands[pokeget]:-}
    [[ -n $pokemon ]] && "$pokemon" random --hide-name 2>/dev/null
    print
  }
fi
if [[ -r "$XDG_CACHE_HOME/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "$XDG_CACHE_HOME/p10k-instant-prompt-${(%):-%n}.zsh"
fi
PROMPT_EOL_MARK=''
if [[ -z $SSH_CLIENT && -z $SSH_TTY && -z $SSH_CONNECTION ]]; then
  typeset -gix P9K_SSH=0
  typeset -gx _P9K_SSH_TTY=$TTY
fi

typeset -g +x ANTIDOTE_HOME=$XDG_CACHE_HOME/antidote
source "$ZDOTDIR/.zstyles"
source "$ZDOTDIR/config/ui/theme.zsh"
source "$ZDOTDIR/lib/antidote.zsh"
source "$ZDOTDIR/config/core/options.zsh"
typeset -g +x ZSH_AUTOSUGGEST_MANUAL_REBIND=1 ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
source "$ZDOTDIR/.zsh_plugins.zsh"
# The plugin enables async while loading; keep the intended setting explicit.
typeset -g +x ZSH_AUTOSUGGEST_USE_ASYNC=1
# Plugins finish changing PATH first, avoiding a second mise hook at precmd.
(( $+commands[mise] )) && eval "$(command mise activate zsh)"
source "$ZDOTDIR/lib/generated.zsh"
source "$ZDOTDIR/lib/compinit.zsh"
source "$ZDOTDIR/config/plugins/fzf.zsh"
source "$ZDOTDIR/config/plugins/zoxide.zsh"
source "$ZDOTDIR/.p10k.zsh"

[[ -r "$ZDOTDIR/config/integrations/$ZDOTS_PLATFORM.zsh" ]] &&
  source "$ZDOTDIR/config/integrations/$ZDOTS_PLATFORM.zsh"
source "$ZDOTDIR/config/integrations/age-secrets.zsh"
source "$ZDOTDIR/config/integrations/terminal.zsh"
source "$ZDOTDIR/config/integrations/remote.zsh"
source "$ZDOTDIR/config/integrations/herdr-shell.zsh"

source "$ZDOTDIR/config/ui/aliases.zsh"
source "$ZDOTDIR/config/ui/functions.zsh"
source "$ZDOTDIR/config/ui/editor.zsh"
source "$ZDOTDIR/config/ui/globalias.zsh"
source "$ZDOTDIR/config/ui/fzf-widgets.zsh"
source "$ZDOTDIR/config/ui/autosuggestions.zsh"
source "$ZDOTDIR/lib/recompile.zsh"

# Patina must see the final widgets. Its activation manages its daemon.
source "$ZDOTDIR/config/plugins/patina.zsh"
if [[ ${ZPROFRC:-0} == 1 ]]; then zprof; fi
