# Rose Pine Moon (dark) — fast-syntax-highlighting theme
# Mirrors fish's Rosé Pine Moon syntax highlighting colors
# Palette: https://rosepinetheme.com/palette

# ── Truecolor ANSI exports (for use in prompts, scripts) ──
export TERM16M_THEME="rose-pine-moon"
export TERM16M_BASE="35;33;54"
export TERM16M_SURFACE="42;39;63"
export TERM16M_OVERLAY="57;53;82"
export TERM16M_MUTED="110;106;134"
export TERM16M_SUBTLE="144;140;170"
export TERM16M_TEXT="224;222;244"
export TERM16M_LOVE="235;111;146"
export TERM16M_GOLD="246;193;119"
export TERM16M_ROSE="234;154;151"
export TERM16M_PINE="62;143;176"
export TERM16M_FOAM="156;207;216"
export TERM16M_IRIS="196;167;231"
export TERM16M_SEL_L="42;40;62"
export TERM16M_SEL_M="68;65;90"
export TERM16M_SEL_H="86;82;110"

typeset -gA FAST_HIGHLIGHT_STYLES

# ── Base tokens ───────────────────────────────────────────
FAST_HIGHLIGHT_STYLES[default]='fg=#e0def4'
FAST_HIGHLIGHT_STYLES[unknown-token]='fg=#eb6f92,bold'
FAST_HIGHLIGHT_STYLES[commandseparator]='fg=#908caa'
FAST_HIGHLIGHT_STYLES[redirection]='fg=#3e8fb0'
FAST_HIGHLIGHT_STYLES[here-string-tri]='fg=#f6c177'
FAST_HIGHLIGHT_STYLES[here-string-text]='bg=#232136'
FAST_HIGHLIGHT_STYLES[here-string-var]='fg=#9ccfd8,bg=#232136'
FAST_HIGHLIGHT_STYLES[exec-descriptor]='fg=#f6c177,bold'
FAST_HIGHLIGHT_STYLES[comment]='fg=#908caa'
FAST_HIGHLIGHT_STYLES[correct-subtle]='bg=#3e8fb0'
FAST_HIGHLIGHT_STYLES[incorrect-subtle]='bg=#eb6f92'
FAST_HIGHLIGHT_STYLES[subtle-separator]='fg=#908caa'
FAST_HIGHLIGHT_STYLES[subtle-bg]='bg=#2a273f'
FAST_HIGHLIGHT_STYLES[secondary]='free'
FAST_HIGHLIGHT_STYLES[recursive-base]='fg=#c4a7e7'

# ── Commands ──────────────────────────────────────────────
FAST_HIGHLIGHT_STYLES[reserved-word]='fg=#9ccfd8'
FAST_HIGHLIGHT_STYLES[subcommand]='fg=#c4a7e7'
FAST_HIGHLIGHT_STYLES[alias]='fg=#c4a7e7'
FAST_HIGHLIGHT_STYLES[suffix-alias]='fg=#c4a7e7'
FAST_HIGHLIGHT_STYLES[global-alias]='bg=#393552'
FAST_HIGHLIGHT_STYLES[builtin]='fg=#c4a7e7'
FAST_HIGHLIGHT_STYLES[function]='fg=#c4a7e7'
FAST_HIGHLIGHT_STYLES[command]='fg=#c4a7e7'
FAST_HIGHLIGHT_STYLES[precommand]='fg=#c4a7e7'
FAST_HIGHLIGHT_STYLES[hashed-command]='fg=#c4a7e7'
FAST_HIGHLIGHT_STYLES[single-sq-bracket]='fg=#c4a7e7'
FAST_HIGHLIGHT_STYLES[double-sq-bracket]='fg=#c4a7e7'
FAST_HIGHLIGHT_STYLES[double-paren]='fg=#9ccfd8'

# ── Paths & globbing ──────────────────────────────────────
# Moon rose = #ea9a97
FAST_HIGHLIGHT_STYLES[path]='fg=#ea9a97'
FAST_HIGHLIGHT_STYLES[path-to-dir]='fg=#ea9a97,underline'
FAST_HIGHLIGHT_STYLES[path_pathseparator]='fg=#908caa'
FAST_HIGHLIGHT_STYLES[globbing]='fg=#9ccfd8'
FAST_HIGHLIGHT_STYLES[globbing-ext]='fg=#3e8fb0'

# ── Arguments & strings ───────────────────────────────────
FAST_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#9ccfd8'
FAST_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#9ccfd8'
FAST_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#908caa'
FAST_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#f6c177'
FAST_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#f6c177'
FAST_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#f6c177'
FAST_HIGHLIGHT_STYLES[optarg-string]='fg=#f6c177'
FAST_HIGHLIGHT_STYLES[optarg-number]='fg=#ea9a97'

# ── Escape sequences ──────────────────────────────────────
FAST_HIGHLIGHT_STYLES[back-or-dollar-double-quoted-argument]='fg=#3e8fb0'
FAST_HIGHLIGHT_STYLES[back-dollar-quoted-argument]='fg=#3e8fb0'

# ── Variables & assignment ────────────────────────────────
FAST_HIGHLIGHT_STYLES[variable]='fg=#e0def4'
FAST_HIGHLIGHT_STYLES[assign]='fg=#908caa'
FAST_HIGHLIGHT_STYLES[assign-array-bracket]='fg=#c4a7e7'
FAST_HIGHLIGHT_STYLES[history-expansion]='fg=#3e8fb0,bold'

# ── Math ──────────────────────────────────────────────────
FAST_HIGHLIGHT_STYLES[mathvar]='fg=#c4a7e7,bold'
FAST_HIGHLIGHT_STYLES[mathnum]='fg=#ea9a97'
FAST_HIGHLIGHT_STYLES[matherr]='fg=#eb6f92'

# ── For-loop ──────────────────────────────────────────────
FAST_HIGHLIGHT_STYLES[for-loop-variable]='fg=#e0def4'
FAST_HIGHLIGHT_STYLES[for-loop-number]='fg=#ea9a97'
FAST_HIGHLIGHT_STYLES[for-loop-operator]='fg=#9ccfd8'
FAST_HIGHLIGHT_STYLES[for-loop-separator]='fg=#908caa'

# ── Case ──────────────────────────────────────────────────
FAST_HIGHLIGHT_STYLES[case-input]='fg=#c4a7e7'
FAST_HIGHLIGHT_STYLES[case-parentheses]='fg=#9ccfd8'
FAST_HIGHLIGHT_STYLES[case-condition]='bg=#2a273f'

# ── Brackets ──────────────────────────────────────────────
FAST_HIGHLIGHT_STYLES[paired-bracket]='bg=#393552'
FAST_HIGHLIGHT_STYLES[bracket-level-1]='fg=#f6c177'
FAST_HIGHLIGHT_STYLES[bracket-level-2]='fg=#c4a7e7'
FAST_HIGHLIGHT_STYLES[bracket-level-3]='fg=#9ccfd8'
