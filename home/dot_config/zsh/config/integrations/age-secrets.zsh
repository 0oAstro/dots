# Encrypted local secrets.

_zdots_source_secrets() {
  emulate -L zsh
  setopt no_aliases

  local enc=$ZDOTDIR/.zshrc.local.age
  local key=$HOME/.config/age/keys.txt
  local out

  [[ -r $enc ]] || return 0
  [[ -r $key ]] || return 1

  out=$(age -d -i "$key" -- "$enc") || return 1
  source /dev/stdin <<< "$out"
}

_zdots_source_secrets

secrets-load() {
  _zdots_source_secrets
}

edit-secrets() {
  emulate -L zsh
  setopt no_aliases

  local enc=$ZDOTDIR/.zshrc.local.age
  local key=$HOME/.config/age/keys.txt
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
  local recipient

  [[ -r $plain ]] || { print -ru2 "missing $plain"; return 1; }
  [[ -r $key ]] || { print -ru2 "secrets-encrypt-age: age key $key not found"; return 1; }

  recipient=$(age-keygen -y "$key") || return
  age -r "$recipient" -o "$out" "$plain" && chmod 600 "$out"
}
