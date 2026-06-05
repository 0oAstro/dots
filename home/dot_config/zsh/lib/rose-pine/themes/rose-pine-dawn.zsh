# Rose Pine Dawn (light) — fast-syntax-highlighting theme
# Mirrors fish's Rosé Pine Dawn syntax highlighting colors
# Palette: https://rosepinetheme.com/palette

# ── Truecolor ANSI exports (for use in prompts, scripts) ──
export TERM16M_THEME="rose-pine-dawn"
export TERM16M_BASE="250;244;237"
export TERM16M_SURFACE="255;250;243"
export TERM16M_OVERLAY="242;233;222"
export TERM16M_MUTED="152;147;165"
export TERM16M_SUBTLE="121;117;147"
export TERM16M_TEXT="87;82;121"
export TERM16M_LOVE="180;99;122"
export TERM16M_GOLD="234;157;52"
export TERM16M_ROSE="215;130;126"
export TERM16M_PINE="40;105;131"
export TERM16M_FOAM="86;148;159"
export TERM16M_IRIS="144;122;169"
export TERM16M_SEL_L="244;237;232"
export TERM16M_SEL_M="223;218;217"
export TERM16M_SEL_H="206;202;205"

typeset -gA FAST_HIGHLIGHT_STYLES

# ── Base tokens ───────────────────────────────────────────
FAST_HIGHLIGHT_STYLES[default]='fg=#575279'
FAST_HIGHLIGHT_STYLES[unknown-token]='fg=#b4637a,bold'
FAST_HIGHLIGHT_STYLES[commandseparator]='fg=#797593'
FAST_HIGHLIGHT_STYLES[redirection]='fg=#286983'
FAST_HIGHLIGHT_STYLES[here-string-tri]='fg=#ea9d34'
FAST_HIGHLIGHT_STYLES[here-string-text]='bg=#faf4ed'
FAST_HIGHLIGHT_STYLES[here-string-var]='fg=#56949f,bg=#faf4ed'
FAST_HIGHLIGHT_STYLES[exec-descriptor]='fg=#ea9d34,bold'
FAST_HIGHLIGHT_STYLES[comment]='fg=#797593'
FAST_HIGHLIGHT_STYLES[correct-subtle]='bg=#286983'
FAST_HIGHLIGHT_STYLES[incorrect-subtle]='bg=#b4637a'
FAST_HIGHLIGHT_STYLES[subtle-separator]='fg=#797593'
FAST_HIGHLIGHT_STYLES[subtle-bg]='bg=#fffaf3'
FAST_HIGHLIGHT_STYLES[secondary]='free'
FAST_HIGHLIGHT_STYLES[recursive-base]='fg=#907aa9'

# ── Commands ──────────────────────────────────────────────
FAST_HIGHLIGHT_STYLES[reserved-word]='fg=#56949f'
FAST_HIGHLIGHT_STYLES[subcommand]='fg=#907aa9'
FAST_HIGHLIGHT_STYLES[alias]='fg=#907aa9'
FAST_HIGHLIGHT_STYLES[suffix-alias]='fg=#907aa9'
FAST_HIGHLIGHT_STYLES[global-alias]='bg=#f2e9e1'
FAST_HIGHLIGHT_STYLES[builtin]='fg=#907aa9'
FAST_HIGHLIGHT_STYLES[function]='fg=#907aa9'
FAST_HIGHLIGHT_STYLES[command]='fg=#907aa9'
FAST_HIGHLIGHT_STYLES[precommand]='fg=#907aa9'
FAST_HIGHLIGHT_STYLES[hashed-command]='fg=#907aa9'
FAST_HIGHLIGHT_STYLES[single-sq-bracket]='fg=#907aa9'
FAST_HIGHLIGHT_STYLES[double-sq-bracket]='fg=#907aa9'
FAST_HIGHLIGHT_STYLES[double-paren]='fg=#56949f'

# ── Paths & globbing ──────────────────────────────────────
FAST_HIGHLIGHT_STYLES[path]='fg=#d7827e'
FAST_HIGHLIGHT_STYLES[path-to-dir]='fg=#d7827e,underline'
FAST_HIGHLIGHT_STYLES[path_pathseparator]='fg=#797593'
FAST_HIGHLIGHT_STYLES[globbing]='fg=#56949f'
FAST_HIGHLIGHT_STYLES[globbing-ext]='fg=#286983'

# ── Arguments & strings ───────────────────────────────────
FAST_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#56949f'
FAST_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#56949f'
FAST_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#797593'
FAST_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#ea9d34'
FAST_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#ea9d34'
FAST_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#ea9d34'
FAST_HIGHLIGHT_STYLES[optarg-string]='fg=#ea9d34'
FAST_HIGHLIGHT_STYLES[optarg-number]='fg=#d7827e'

# ── Escape sequences ──────────────────────────────────────
FAST_HIGHLIGHT_STYLES[back-or-dollar-double-quoted-argument]='fg=#286983'
FAST_HIGHLIGHT_STYLES[back-dollar-quoted-argument]='fg=#286983'

# ── Variables & assignment ────────────────────────────────
FAST_HIGHLIGHT_STYLES[variable]='fg=#575279'
FAST_HIGHLIGHT_STYLES[assign]='fg=#797593'
FAST_HIGHLIGHT_STYLES[assign-array-bracket]='fg=#907aa9'
FAST_HIGHLIGHT_STYLES[history-expansion]='fg=#286983,bold'

# ── Math ──────────────────────────────────────────────────
FAST_HIGHLIGHT_STYLES[mathvar]='fg=#907aa9,bold'
FAST_HIGHLIGHT_STYLES[mathnum]='fg=#d7827e'
FAST_HIGHLIGHT_STYLES[matherr]='fg=#b4637a'

# ── For-loop ──────────────────────────────────────────────
FAST_HIGHLIGHT_STYLES[for-loop-variable]='fg=#575279'
FAST_HIGHLIGHT_STYLES[for-loop-number]='fg=#d7827e'
FAST_HIGHLIGHT_STYLES[for-loop-operator]='fg=#56949f'
FAST_HIGHLIGHT_STYLES[for-loop-separator]='fg=#797593'

# ── Case ──────────────────────────────────────────────────
FAST_HIGHLIGHT_STYLES[case-input]='fg=#907aa9'
FAST_HIGHLIGHT_STYLES[case-parentheses]='fg=#56949f'
FAST_HIGHLIGHT_STYLES[case-condition]='bg=#fffaf3'

# ── Brackets ──────────────────────────────────────────────
FAST_HIGHLIGHT_STYLES[paired-bracket]='bg=#f2e9e1'
FAST_HIGHLIGHT_STYLES[bracket-level-1]='fg=#ea9d34'
FAST_HIGHLIGHT_STYLES[bracket-level-2]='fg=#907aa9'
FAST_HIGHLIGHT_STYLES[bracket-level-3]='fg=#56949f'
