#!/bin/zsh
[[ ${ZPROFRC:-0} == 1 ]] && zmodload zsh/zprof
#
# .zshrc — Zsh interactive shell entry point.
# Source source files only. zsh automatically uses adjacent .zwc bytecode when
# it is newer than the source; explicitly sourcing *.zwc is not reliable.
# After edits run: recompile
#

# Avoid zsh's reverse-video '%' marker when any startup command leaves a partial
# line. This also prevents prompt artifacts with Starship/fzf redraws.
PROMPT_EOL_MARK=''

# ── Pokemon greeting (opt-in; real terminal only) ─────────────────
# Enable with: export ZDOTS_GREETING=1
if [[ -n ${ZDOTS_GREETING:-} && -t 0 && -t 1 && -z ${ZSH_EXECUTION_STRING:-} ]] && (( $+commands[pokeget] )); then
  () {
    setopt localoptions noprompt_sp noprompt_cr
    pokeget random --hide-name 2>/dev/null
    print
  }
fi

# NOTE: The old hand-rolled instant prompt printed a fake prompt and moved the
# cursor up. It raced Starship and caused stray '%' / misplaced prompt lines.
# Starship itself is loaded below from a compiled cache.

# ── zstyles (sourced early — antidote bootstrap needs them) ──────
[[ -r $ZDOTDIR/.zstyles ]] && source $ZDOTDIR/.zstyles

# ── Antidote plugin bootstrap ────────────────────────────────────
local _plugins_txt=$ZDOTDIR/.zsh_plugins.txt
local _plugins_zsh=$ZDOTDIR/.zsh_plugins.zsh

# Bootstrap antidote if missing. Prefer git; fallback to curl/wget tarball.
if [[ ! -d $ZDOTDIR/.antidote ]]; then
  if (( $+commands[git] )); then
    git clone --depth 1 --quiet https://github.com/mattmc3/antidote $ZDOTDIR/.antidote 2>/dev/null
  elif (( $+commands[curl] || $+commands[wget] )) && (( $+commands[tar] )); then
    local _ad_tmp=${TMPDIR:-/tmp}/antidote.$$ _ad_url=https://github.com/mattmc3/antidote/archive/refs/heads/main.tar.gz
    command mkdir -p $_ad_tmp 2>/dev/null
    if (( $+commands[curl] )); then
      command curl -fsSL $_ad_url | command tar -xz -C $_ad_tmp 2>/dev/null
    else
      command wget -O- $_ad_url | command tar -xz -C $_ad_tmp 2>/dev/null
    fi
    command mv $_ad_tmp/antidote-main $ZDOTDIR/.antidote 2>/dev/null
    command rm -rf $_ad_tmp 2>/dev/null
    unset _ad_tmp _ad_url
  fi
fi

# Regenerate static plugin file when .txt is newer than .zsh or ANTIDOTE_HOME
# changes (macOS <-> Linux). The marker avoids stale platform-specific paths.
local _plugins_marker _plugins_first
_plugins_marker="# ANTIDOTE_HOME=$ANTIDOTE_HOME"
if [[ -r $_plugins_zsh ]]; then IFS= read -r _plugins_first < $_plugins_zsh; fi
if [[ -r $_plugins_txt && (! -f $_plugins_zsh || $_plugins_txt -nt $_plugins_zsh || $_plugins_first != $_plugins_marker) ]]; then
  if [[ -r $ZDOTDIR/.antidote/functions/antidote || -r $ZDOTDIR/.antidote/antidote.zsh ]]; then
    fpath=($ZDOTDIR/.antidote/functions $ZDOTDIR/.antidote $fpath)
    autoload -Uz antidote
    { print -r -- $_plugins_marker; antidote bundle <$_plugins_txt; } >|$_plugins_zsh 2>/dev/null
  fi
fi
unset _plugins_marker _plugins_first

# ── Starship prompt (source .zsh; zsh auto-uses newer .zwc) ───────
if (( $+commands[starship] )); then
  () {
    local _cache=$XDG_CACHE_HOME/starship/init.zsh
    local _bin=${commands[starship]}
    if [[ ! -r $_cache || $_bin -nt $_cache ]]; then
      command mkdir -p ${_cache:h} 2>/dev/null
      $_bin init zsh >| $_cache 2>/dev/null && zcompile $_cache 2>/dev/null
    fi
    [[ -r $_cache ]] && source $_cache
    # starship.toml has no right prompt; avoid the extra starship --right fork/redraw.
    RPROMPT=
  }
else
  PROMPT=$'%F{cyan}%~%f
%F{magenta}❯%f '
fi

# ── Modular config (source .zsh; zsh auto-loads adjacent newer .zwc) ──
local _cfg=$ZDOTDIR/config
source $_cfg/00-opts.zsh
source $_cfg/01-plugins.zsh
source $_cfg/02-theme.zsh
source $_cfg/03-completions.zsh
source $_cfg/04-env.zsh
source $_cfg/05-aliases.zsh
source $_cfg/06-funcs.zsh
source $_cfg/07-widgets.zsh
source $_cfg/08-prompt.zsh
source $_cfg/09-z4h-integrations.zsh

# ── Age-encrypted local secrets (synced via git, decrypted at runtime) ──
# Requires age identity at ~/.config/age/keys.txt
if [[ -r $ZDOTDIR/.zshrc.local.age ]] && (( $+commands[age] )); then
  local _age_key="$HOME/.config/age/keys.txt"
  [[ -r $_age_key ]] && eval "$(age -d -i $_age_key $ZDOTDIR/.zshrc.local.age 2>/dev/null)"
  unset _age_key
fi

# ── Recompile helper ─────────────────────────────────────────────
recompile() {
  emulate -L zsh
  local f
  for f in \
    "$ZDOTDIR/.zshenv" \
    "$ZDOTDIR/.zshrc" \
    "$ZDOTDIR/.zstyles" \
    "$ZDOTDIR/.zsh_plugins.zsh" \
    "$ZDOTDIR"/config/*.zsh(N); do
    [[ -r $f ]] || continue
    zcompile "$f" && print "✓ ${f#$ZDOTDIR/}"
  done
}

[[ ${ZPROFRC:-0} == 1 ]] && zprof
true
