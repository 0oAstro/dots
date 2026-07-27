# Encrypted local secrets.
#
# Threat model: age protects secrets in a public/synced git repo, not the local
# machine. A 0600 plaintext cache under $XDG_CACHE_HOME is an accepted trade for
# startup latency — fast path sources it when fresh; cold/stale path decrypts
# synchronously once, atomically replaces the cache, then sources it.

_zdots_secrets_enc=$ZDOTDIR/.zshrc.local.age
_zdots_secrets_key=$HOME/.config/age/keys.txt
_zdots_secrets_cache=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zshrc.local

_zdots_secrets_cache_fresh() {
  emulate -L zsh
  setopt no_aliases

  local enc=$1 cache=$2
  [[ -r $cache && ! $enc -nt $cache ]]
}

_zdots_build_secrets_cache() {
  emulate -L zsh
  setopt no_aliases

  local enc=$_zdots_secrets_enc key=$_zdots_secrets_key cache=$_zdots_secrets_cache
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

  local enc=$_zdots_secrets_enc key=$_zdots_secrets_key cache=$_zdots_secrets_cache

  [[ -r $enc ]] || return 0
  [[ -r $key ]] || return 1

  if ! _zdots_secrets_cache_fresh "$enc" "$cache"; then
    _zdots_build_secrets_cache || return 1
  fi

  source "$cache"
}

_zdots_edit_secrets_invoke() {
  emulate -L zsh
  setopt no_aliases

  local plain=$1

  if [[ ${EDITOR:t} == nvim ]]; then
    "$EDITOR" -n -i NONE -c 'set noundofile nobackup nowritebackup noswapfile' -- "$plain"
  else
    print -ru2 'edit-secrets: warning: EDITOR is not nvim; plaintext may leak into editor state'
    "$EDITOR" -- "$plain"
  fi
}

_zdots_source_secrets

secrets-load() {
  _zdots_source_secrets
}

secrets-refresh() {
  _zdots_build_secrets_cache && _zdots_source_secrets
}

edit-secrets() {
  emulate -L zsh
  setopt no_aliases

  local enc=$_zdots_secrets_enc key=$_zdots_secrets_key cache=$_zdots_secrets_cache
  local plain before recipient rel tmpdir

  [[ -r $key ]] || { print -ru2 "edit-secrets: age key $key not found"; return 1; }
  [[ -n $EDITOR ]] || { print -ru2 'edit-secrets: EDITOR is not set'; return 1; }

  tmpdir=${${TMPDIR:-/tmp}%/}
  umask 077
  plain=$(command mktemp "${tmpdir}/.zshrc.local.XXXXXX") || return 1
  before=$(command mktemp "${tmpdir}/.zshrc.local.before.XXXXXX") || { command rm -f -- "$plain"; return 1; }
  {
    [[ -r $enc ]] && age -d -i "$key" -- "$enc" >| "$plain" 2>/dev/null
    command cp -- "$plain" "$before" || return
    _zdots_edit_secrets_invoke "$plain" || return
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
  local out=$_zdots_secrets_enc
  local key=$_zdots_secrets_key
  local cache=$_zdots_secrets_cache
  local recipient

  [[ -r $plain ]] || { print -ru2 "missing $plain"; return 1; }
  [[ -r $key ]] || { print -ru2 "secrets-encrypt-age: age key $key not found"; return 1; }

  recipient=$(age-keygen -y "$key") || return
  age -r "$recipient" -o "$out" "$plain" && chmod 600 "$out" && {
    command mkdir -p -- "${cache:h}" 2>/dev/null
    command cp -- "$plain" "$cache" 2>/dev/null && command chmod 600 -- "$cache" 2>/dev/null
  }
}
