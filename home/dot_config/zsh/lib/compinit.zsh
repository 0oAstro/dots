# compinit prep. compinit itself is handled by mattmc3/ez-compinit.
#
# This has to run before config/plugins/load.zsh: ez-compinit calls compstyleinit
# at plugin-load time, which pulls compinit in with it. Anything set afterwards
# is too late, so $fpath here is still the pre-plugin one.

_comp_options+=(globdots)
ZSH_COMPDUMP=$XDG_CACHE_HOME/zsh/zcompdump-$HOST

# Drop a stale dump so new completions show up on the next shell rather than
# waiting out ez-compinit's 20h cache window. Plugin fpath entries do not exist
# yet, so stand in for them with the antidote bundle and plugin root, both of
# which change whenever the plugin set does.
() {
  emulate -L zsh -o extended_glob
  local dump=$ZSH_COMPDUMP
  [[ -s $dump ]] || return 0
  local -a newer=(
    ${^fpath}(N/e:'[[ $REPLY -nt $dump ]]':)
    $ZDOTDIR/.zsh_plugins.zsh(N.e:'[[ $REPLY -nt $dump ]]':)
    $ANTIDOTE_HOME(N/e:'[[ $REPLY -nt $dump ]]':)
  )
  (( $#newer )) && command rm -f -- "$dump" "$dump".zwc
}
