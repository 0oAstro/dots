#!/usr/bin/env bash

# set theme to left & right statuses
set_status() {
  # left or right
  local -r side="$1"
  local -r option="status-$side"

  # get mooks theme options from tmux
  local -r status=$(get_tmux_option -g "$option" | sed $'s/||/\\\n/g')
  local -r status_colors_bg=$(get_tmux_option -g "@status-${side}-colors-bg")
  local -r status_colors_fg=$(get_tmux_option -g "@status-${side}-colors-fg")
  local -r status_sep_first=$(get_tmux_option -g "@status-${side}-sep-first")
  local -r status_sep_last=$(get_tmux_option -g "@status-${side}-sep-last")
  local -r status_sep_left=$(get_tmux_option -g "@status-${side}-sep-left")
  local -r status_sep_right=$(get_tmux_option -g "@status-${side}-sep-right")

  IFS=$'\n' read -rd '' -a parts <<< "$status"
  IFS=':' read -r -a colors_bg <<< "$status_colors_bg"
  IFS=':' read -r -a colors_fg <<< "$status_colors_fg"

  # clean tmux status strings
  set_tmux_option -g "$option" ""

  # set index of utmost widget on side
  if [ "$side" == "left" ]; then
    first_index=0
  elif [ "$side" == "right" ]; then
    first_index=$(( ${#parts[@]} - 1 ))
  fi

  i=0
  for part in "${parts[@]}"; do
    color_index_bg=$(( i % ${#colors_bg[@]} ))
    color_bg=${colors_bg[$color_index_bg]}
    color_index_fg=$(( i % ${#colors_fg[@]} ))
    color_fg=${colors_fg[$color_index_fg]}

    # set colors of separators
    if [ "$side" == "left" ]; then
      color_sep_left="#[fg=$color_fg,bg=$color_bg]"
      color_sep_right="#[fg=$color_bg,bg=$color_fg]"
    elif [ "$side" == "right" ]; then
      color_sep_left="#[fg=$color_bg,bg=$color_fg]"
      color_sep_right="#[fg=$color_fg,bg=$color_bg]"
    fi

    # check presence of #[noseparator] attr
    if [[ "$part" =~ \#\[(.*,)?noseparator(,.*)?\] ]]; then
      noseparator="true"
    else
      noseparator="false"
    fi

    widget=""

    # form widget
    if [ $i -eq "$first_index" ]; then
      if [ "$noseparator" == "false" ]; then widget+="$color_sep_left$status_sep_first"; fi
      widget+="#[fg=$color_fg,bg=$color_bg]$part"
      if [ "$noseparator" == "false" ]; then widget+="$color_sep_right$status_sep_last"; fi
		else
      if [ "$noseparator" == "false" ]; then widget+="$color_sep_left$status_sep_left"; fi
      widget+="#[fg=$color_fg,bg=$color_bg]$part"
      if [ "$noseparator" == "false" ]; then widget+="$color_sep_right$status_sep_right"; fi
    fi

    # set status
    add_tmux_option -g "$option" "$widget"
    ((i++))
  done
}

# set theme to windows
set_window() {
  # inactive or active
  type="$1"
  if [ "$type" == "inactive" ]; then
    local -r option="window-status-format"
  elif [ "$type" == "current" ]; then
    local -r option="window-status-current-format"
  fi

  local -r status=$(get_tmux_option -g "${option}")
  local -r color_bg=$(get_tmux_option -g "@window-status-${type}-format-bg")
  local -r color_sep_bg=$(get_tmux_option -g "@window-status-${type}-format-sep-bg")
  local -r color_fg=$(get_tmux_option -g "@window-status-${type}-format-fg")
  local -r color_sep_fg=$(get_tmux_option -g "@window-status-${type}-format-sep-fg")
  local -r sep_left=$(get_tmux_option -g "@window-status-format-sep-left")
  local -r sep_right=$(get_tmux_option -g "@window-status-format-sep-right")

  set_tmux_option -g "${option}" ""
  set_tmux_option -g "${option}" "#[fg=$color_sep_fg,bg=$color_sep_bg]$sep_left #[fg=$color_fg,bg=$color_bg]$status#[fg=$color_sep_bg,bg=$color_sep_fg]$sep_right"
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/lib/variables.sh"
source "$DIR/lib/utils.sh"

mooks_theme_status_enable=$(get_tmux_option -g "$opt_mooks_theme_status_enable")
declare -r mooks_theme_status_enable

# exit if status script is disabled
if [ "$mooks_theme_status_enable" != "true" ]; then
  exit 0
fi

set_status "left"
set_status "right"
set_window "current"
set_window "inactive"
