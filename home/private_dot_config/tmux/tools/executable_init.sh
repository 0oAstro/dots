#!/usr/bin/env bash

println() {
  msg="$1"
  if [ -z "$QUIET" ]; then
    echo "$msg"
  fi
}

# install tmux.conf if not exist
install_tmux_conf() {
  # check if tmux.conf already exist
  if [ -f "$TMUX_DIR/tmux.conf" ]; then
    # check if it a symlink to mooks
    if [ "$(readlink "$TMUX_DIR/tmux.conf")" == "$MOOKS_DIR/tmux.conf" ]; then
      install_conf="false"
      SUCC="true"
    else
      # ask user if not
      read -rp "file $TMUX_DIR/tmux.conf already exists, replace? [y/N]: " install_conf
      install_conf=${install_conf:-false}

      if [[ "$install_conf" =~ ^[Yy](es)?$ ]]; then
        install_conf="true"
      fi
    fi
  else
    install_conf="true"
  fi

  # link tmux.conf to mooks/tmux.conf if not exist
  if [ "$install_conf" == "true" ]; then
    println ""
    println "linking $TMUX_DIR/tmux.conf:"
    println "  ln -sf $MOOKS_DIR/tmux.conf $TMUX_DIR/tmux.conf"
    ln -sf "$MOOKS_DIR/tmux.conf" "$TMUX_DIR/tmux.conf"
    SUCC="true"
  fi
}

update_mooks() {
  # fetch remote rev
  cd "$MOOKS_DIR" && git fetch --quiet

  local -r local_rev=$(git rev-parse HEAD)
  local -r remote_rev=$(git rev-parse '@{u}')

  # update if new rev exists
  if [ "$local_rev" != "$remote_rev" ]; then
    if [[ -n $TMUX ]]; then tmux display-message "Updating mooks"; fi

    GIT_TERMINAL_PROMPT=0 git pull >/dev/null
  fi
}

# create dirs in tmux config dir
create_dirs() {
  local -n dirs="$1"

  for dir in "${dirs[@]}"; do
    if [ ! -d "$TMUX_DIR/$dir" ]; then
      println "  mkdir $TMUX_DIR/$dir"
	    mkdir -p "$TMUX_DIR/$dir"
    fi
  done
}

# create empty files in tmux config dir
create_files() {
  local -n files="$1"

  for file in "${files[@]}"; do
    if [ ! -f "$TMUX_DIR/conf.d/$file" ]; then
      println "  touch $TMUX_DIR/conf.d/$file"
	    touch "$TMUX_DIR/conf.d/$file"
    fi
  done
}

# copy main.conf and set init paths
cp_main_conf() {
  if [ ! -f "$TMUX_DIR/conf.d/main.conf" ]; then
    println "  cp $MOOKS_DIR/conf.d/main.conf $TMUX_DIR/conf.d/main.conf"
    cp "$MOOKS_DIR/conf.d/main.conf" "$TMUX_DIR/conf.d/main.conf"
    set_paths
  fi
}

# set mooks paths in main.conf
set_paths() {
  sed -i "s|@mooks-dir '[^']*'|@mooks-dir '$MOOKS_DIR'|" "$TMUX_DIR/conf.d/main.conf"
  sed -i "s|@mooks-install-dir '[^']*'|@mooks-install-dir '$MOOKS_DIR'|" "$TMUX_DIR/conf.d/main.conf"
  sed -i "s|@mooks-tmux-conf '[^']*'|@mooks-tmux-conf '$MOOKS_DIR/tmux.conf'|" "$TMUX_DIR/conf.d/main.conf"
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MOOKS_DIR="$(dirname "$DIR")"
source "$DIR/lib/variables.sh"
source "$DIR/lib/utils.sh"

#declare mooks_skip_init mooks_autoupdate_enable
mooks_skip_init=$(get_tmux_option -g "$opt_mooks_skip_init")
mooks_autoupdate_enable=$(get_tmux_option -g "$opt_mooks_autoupdate_enable")
#declare -r mooks_skip_init=$(get_tmux_option -g "$opt_mooks_skip_init")
#declare -r mooks_autoupdate_enable=$(get_tmux_option -g "$opt_mooks_autoupdate_enable")
declare -r mooks_skip_init mooks_autoupdate_enable

# shellcheck disable=SC2034
declare -a conf_dirs=("conf.d" "plugins" "scripts" "themes")
# shellcheck disable=SC2034
declare -a conf_files=("auto_plugins.conf" "bindings.conf" "hooks.conf" "options.conf" "plugins.conf" )

# exit if skip-init is set
if [ "$mooks_skip_init" == "true" ]; then
  exit 0
fi

for arg in "$@"; do
  if [ "$arg" = "-q" ]; then QUIET=true; fi
done

# update mooks if autoupdates enabled
if [ "$mooks_autoupdate_enable" == "true" ]; then update_mooks; fi

SUCC="false"

println "creating directories and files in $TMUX_DIR:"
create_dirs "conf_dirs"
create_files "conf_files"
cp_main_conf
install_tmux_conf

# print init results
if [ "$SUCC" == "true" ]; then
  println ""
  println "Mooks was successfully initialized:"
  println "  mooks dir: $MOOKS_DIR"
  println "  tmux dir: $TMUX_DIR"
  println "Restart terminal app for changes to take effect"
  println ""
  println "NOTE: you need git for auto plugin management and mooks autoupdates"
  println "NOTE: nerd fonts must be used in terminal app for default theme"
else
  println ""
  println "Problem initializing mooks!"
  println "Fix error, rerun init or submit an issue"
fi
