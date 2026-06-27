# Encrypted local secrets.

# Startup strategy:
# - Fast path: source a 0600 plaintext cache when it is present and fresh.
# - Slow path: if the cache is missing/stale, decrypt in the background and source
#   it from the next prompt. A background job cannot mutate this shell's env, so
#   the parent shell must do the final `source`.

_zdots_secrets_paths() {
  emulate -L zsh
  setopt no_aliases

  local enc=$ZDOTDIR/.zshrc.local.age
  local key=$HOME/.config/age/keys.txt
  local cache=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zshrc.local

  print -r -- "$enc" "$key" "$cache"
}

_zdots_secrets_cache_fresh() {
  emulate -L zsh
  setopt no_aliases

  local enc=$1 cache=$2
  [[ -r $cache && ! $enc -nt $cache ]]
}

_zdots_build_secrets_cache() {
  emulate -L zsh
  setopt no_aliases

  local enc=$ZDOTDIR/.zshrc.local.age
  local key=$HOME/.config/age/keys.txt
  local cache=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zshrc.local
  local tmp

  [[ -r $enc ]] || return 0
  [[ -r $key ]] || return 1

  command mkdir -p -- "${cache:h}" || return 1
  tmp=$(command mktemp "${cache}.XXXXXX") || return 1
  {
    command chmod 600 -- "$tmp" 2>/dev/null
    age -d -i "$key" -- "$enc" >| "$tmp" || return 1
    command chmod 600 -- "$tmp" 2>/dev/null
    command mv -f -- "$tmp" "$cache"
  } always {
    [[ -n ${tmp:-} && -e $tmp ]] && command rm -f -- "$tmp"
  }
}

_zdots_source_secrets() {
  emulate -L zsh
  setopt no_aliases

  local enc=$ZDOTDIR/.zshrc.local.age
  local key=$HOME/.config/age/keys.txt
  local cache=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zshrc.local

  [[ -r $enc ]] || return 0
  [[ -r $key ]] || return 1

  if ! _zdots_secrets_cache_fresh "$enc" "$cache"; then
    _zdots_build_secrets_cache || return 1
  fi

  source "$cache"
}

_zdots_source_secrets_deferred() {
  # Keep the public entrypoint name for compatibility with older compiled files
  # and muscle memory, but use the safer startup policy:
  # - cold/stale cache: block once to build it, so the first command has secrets
  # - warm cache: source the cache immediately, which is effectively free
  _zdots_source_secrets
}

_zdots_source_secrets_deferred

secrets-load() {
  _zdots_source_secrets
}

secrets-refresh() {
  _zdots_build_secrets_cache && _zdots_source_secrets
}

edit-secrets() {
  emulate -L zsh
  setopt no_aliases

  local enc=$ZDOTDIR/.zshrc.local.age
  local key=$HOME/.config/age/keys.txt
  local cache=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zshrc.local
  local plain before recipient rel

  [[ -r $key ]] || { print -ru2 "edit-secrets: age key $key not found"; return 1; }
  [[ -n $EDITOR ]] || { print -ru2 'edit-secrets: EDITOR is not set'; return 1; }

  umask 077
  plain=$(command mktemp /tmp/.zshrc.local.XXXXXX) || return 1
  before=$(command mktemp /tmp/.zshrc.local.before.XXXXXX) || { command rm -f -- "$plain"; return 1; }
  {
    [[ -r $enc ]] && age -d -i "$key" -- "$enc" >| "$plain" 2>/dev/null
    command cp -- "$plain" "$before" || return
    "$EDITOR" "$plain" || return
    command cmp -s -- "$before" "$plain" && { print 'edit-secrets: unchanged'; return 0; }

    recipient=$(age-keygen -y "$key") || return
    age -r "$recipient" -o "$enc" "$plain" || return
    chmod 600 "$enc"

    command mkdir -p -- "${cache:h}" 2>/dev/null
    command cp -- "$plain" "$cache" 2>/dev/null && command chmod 600 -- "$cache" 2>/dev/null

    rel=${enc#$ZDOTDIR/}
    git -C "$ZDOTDIR" add -- "$rel" || return
    git -C "$ZDOTDIR" commit -m 'update: secrets' -- "$rel"
  } always {
    command rm -f -- "$plain" "$before"
  }
}

secrets-encrypt-age() {
  emulate -L zsh
  setopt no_aliases

  local plain=$ZDOTDIR/.zshrc.local
  local out=$ZDOTDIR/.zshrc.local.age
  local key=$HOME/.config/age/keys.txt
  local cache=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zshrc.local
  local recipient

  [[ -r $plain ]] || { print -ru2 "missing $plain"; return 1; }
  [[ -r $key ]] || { print -ru2 "secrets-encrypt-age: age key $key not found"; return 1; }

  recipient=$(age-keygen -y "$key") || return
  age -r "$recipient" -o "$out" "$plain" && chmod 600 "$out" && {
    command mkdir -p -- "${cache:h}" 2>/dev/null
    command cp -- "$plain" "$cache" 2>/dev/null && command chmod 600 -- "$cache" 2>/dev/null
  }
}
