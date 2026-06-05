# rose-pine.plugin.zsh — Rose Pine syntax highlighting for fast-syntax-highlighting
#
# Mirrors fish shell's Rosé Pine theme colors token-for-token.
#
# Usage:
#   # in .zshrc, before fast-syntax-highlighting is loaded:
#   export ROSE_PINE_VARIANT="moon"  # optional: dark (default), moon, dawn
#   source /path/to/rose-pine/rose-pine.plugin.zsh
#
# Or call directly after both are loaded:
#   source /path/to/rose-pine/themes/rose-pine-moon.zsh

0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
0="${${(M)0:#/*}:-$PWD/$0}"
ROSE_PINE_DIR="${0:h}"

# ── Truecolor ANSI escape helpers ──────────────────────────────

# Generate a truecolor ANSI escape: set bg + fg from R;G;B triplets
# Usage: term16m_set_color "$TERM16M_BASE" "$TERM16M_IRIS"
# Output: %{\033[48;2;R;G;B;38;2;R;G;Bm%}
term16m_set_color() {
  echo "%{\033[48;2;$1;38;2;$2m%}"
}

# Reset all attributes
: ${TERM16M_RESET:="%{\033[0m%}"}

# ── Theme loader ───────────────────────────────────────────────

_rose_pine_load_theme() {
  local variant="${ROSE_PINE_VARIANT:-}"
  local theme_file

  case "$variant" in
    moon|dawn) theme_file="${ROSE_PINE_DIR}/themes/rose-pine-${variant}.zsh" ;;
    *)         theme_file="${ROSE_PINE_DIR}/themes/rose-pine.zsh" ;;
  esac

  if [[ ! -f "$theme_file" ]]; then
    echo "rose-pine: theme '${variant}' not found at ${theme_file}" >&2
    return 1
  fi

  source "$theme_file"

  # Re-apply the loaded styles into fast-syntax-highlighting's runtime
  if (( ${+commands[fast-theme]} )); then
    fast-theme :plugin:fast-syntax-highlighting:theme rose-pine
  fi
}

_rose_pine_load_theme
