# ── pokeget (fish-style greeting + Ctrl+L pokemon) ─────────────
# Uses precmd hook that removes itself after first run — avoids
# p10k "Console output during zsh initialization detected" warning.
autoload -Uz add-zsh-hook

_pokeget_greeting() {
  pokeget random --hide-name 2>/dev/null
  add-zsh-hook -d precmd _pokeget_greeting
}
add-zsh-hook precmd _pokeget_greeting

_pokeget_clear() { clear; pokeget random --hide-name; zle reset-prompt; }
zle -N _pokeget_clear
