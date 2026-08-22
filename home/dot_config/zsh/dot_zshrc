[[ ${ZPROFRC:-0} == 1 ]] && zmodload zsh/zprof

# Pokemon greeting. Run it before P10k captures terminal output so the art is
# visible immediately and becomes part of the terminal state P10k saves.
if [[ -o interactive && -z ${ZSH_EXECUTION_STRING:-} ]]; then
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

# p10k falls back to forking `who -m` to detect SSH whenever SSH_* is unset.
# Those variables are authoritative here, so answer the question up front.
if [[ -z $SSH_CLIENT && -z $SSH_TTY && -z $SSH_CONNECTION ]]; then
  typeset -gix P9K_SSH=0
  typeset -gx _P9K_SSH_TTY=$TTY
fi

source "$ZDOTDIR/.zstyles"
source "$ZDOTDIR/config/ui/theme.zsh"
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

# Keep mise after all plugins and PATH modifications so its shims win.
if (( $+commands[mise] )); then
  eval "$(mise activate zsh)"
  # Antidote's kind:path plugin prepends this directory; move it behind
  # mise's active tool paths after every plugin has finished changing PATH.
  typeset _mise_git_cmds="$HOME/.cache/antidote/github.com/mattmc3/git-cmds"
  if [[ -d $_mise_git_cmds ]]; then
    path=(${path:#$_mise_git_cmds} $_mise_git_cmds)
  fi
  unset _mise_git_cmds
fi

