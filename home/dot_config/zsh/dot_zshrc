[[ ${ZPROFRC:-0} == 1 ]] && zmodload zsh/zprof

# Enable Powerlevel10k instant prompt. Should stay close to the top of .zshrc.
# Initialization code that may require console input must go above this block;
# everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Pokemon greeting. Kept below the instant prompt block so p10k buffers the art
# and replays it after init instead of holding back the first visible prompt.
# The tty tests the guard used to do are wrong here: instant prompt points fd 1
# at a temp file, so `-o interactive` is what actually distinguishes the cases.
if [[ -o interactive && -z ${ZSH_EXECUTION_STRING:-} ]] && (( $+commands[pokeget] )); then
  () {
    setopt localoptions noprompt_sp noprompt_cr
    pokeget random --hide-name 2>/dev/null
    print
  }
fi

# Interactive shell entry point.

PROMPT_EOL_MARK=''

# p10k falls back to forking `who -m` to detect SSH whenever SSH_* is unset.
# Those variables are authoritative here, so answer the question up front.
if [[ -z $SSH_CLIENT && -z $SSH_TTY && -z $SSH_CONNECTION ]]; then
  typeset -gix P9K_SSH=0
  typeset -gx _P9K_SSH_TTY=$TTY
fi

source "$ZDOTDIR/.zstyles"
source "$ZDOTDIR/lib/antidote.zsh"

source "$ZDOTDIR/config/core/options.zsh"
# Must precede load.zsh: ez-compinit pulls compinit in at plugin-load time, so
# ZSH_COMPDUMP and the staleness check both have to be settled before then.
source "$ZDOTDIR/lib/compinit.zsh"

source "$ZDOTDIR/config/plugins/env.zsh"
source "$ZDOTDIR/config/plugins/load.zsh"
source "$ZDOTDIR/config/plugins/fzf.zsh"
source "$ZDOTDIR/config/plugins/zoxide.zsh"

source "$ZDOTDIR/lib/prompt.zsh"

source "$ZDOTDIR/config/integrations/macos.zsh"
source "$ZDOTDIR/config/integrations/linux.zsh"
source "$ZDOTDIR/config/integrations/age-secrets.zsh"
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

# Loads last: patina wraps ZLE widgets and must see the final set of them.
source "$ZDOTDIR/config/plugins/patina.zsh"
