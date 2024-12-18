{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    autocd = true;
    dirHashes = {
      dl = "$HOME/Downloads";
      docs = "$HOME/Documents";
      code = "$HOME/Public/code";
      dots = "$HOME/Public/code/dots";
      pics = "$HOME/Pictures";
      vids = "$HOME/Movies";
    };
    dotDir = ".config/zsh";
    history = {
      expireDuplicatesFirst = true;
      path = "${config.xdg.dataHome}/zsh_history";
    };

    syntaxHighlighting = {
      enable = true;
      highlighters = ["main" "brackets" "pattern" "regexp" "cursor" "root" "line"];
    };

    initExtra = ''
      # Cycle through history based on characters already typed on the line
      autoload -U up-line-or-beginning-search
      autoload -U down-line-or-beginning-search
      zle -N up-line-or-beginning-search
      zle -N down-line-or-beginning-search
      bindkey "$key[Up]" up-line-or-beginning-search
      bindkey "$key[Down]" down-line-or-beginning-search

      # C-right / C-left for word skips
      bindkey "^[[1;5C" forward-word
      bindkey "^[[1;5D" backward-word

      # C-Backspace / C-Delete for word deletions
      bindkey "^[[3;5~" forward-kill-word
      bindkey "^H" backward-kill-word

      # Home/End
      bindkey "^[[OH" beginning-of-line
      bindkey "^[[OF" end-of-line

      # open commands in $EDITOR with C-e
      autoload -z edit-command-line
      zle -N edit-command-line
      bindkey "^e" edit-command-line

      # case insensitive tab completion
      zstyle ':completion:*' completer _complete _ignored _approximate
      zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      zstyle ':completion:*' menu select
      zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
      zstyle ':completion:*' verbose true

      # use cache for completions
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/.zcompcache"
      _comp_options+=(globdots)

      # fzf tab
      autoload -U compinit; compinit
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

      ${lib.optionalString config.services.gpg-agent.enable ''
        gnupg_path=$(ls $XDG_RUNTIME_DIR/gnupg)
        export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gnupg/$gnupg_path/S.gpg-agent.ssh"
      ''}

      # pokeget
      ${pkgs.pokeget-rs}/bin/pokeget random --hide-name

      # fzf auto coloring kinda
      defaults read -globalDomain AppleInterfaceStyle &> /dev/null && \
        export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
        --color=bg+:#414559,bg:#303446,spinner:#f2d5cf,hl:#e78284 \
        --color=fg:#c6d0f5,header:#e78284,info:#ca9ee6,pointer:#f2d5cf \
        --color=marker:#babbf1,fg+:#c6d0f5,prompt:#ca9ee6,hl+:#e78284 \
        --color=selected-bg:#51576d" \
      || export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
        --color=bg+:#ccd0da,bg:#eff1f5,spinner:#dc8a78,hl:#d20f39 \
        --color=fg:#4c4f69,header:#d20f39,info:#8839ef,pointer:#dc8a78 \
        --color=marker:#7287fd,fg+:#4c4f69,prompt:#8839ef,hl+:#d20f39 \
        --color=selected-bg:#bcc0cc"
    '';

    shellAliases = {
      grep = "rg";
      l = "eza -l";
      la = "eza -la";
      md = "mkdir -p";
      ls = "eza -laHG --icons --git";
      rm = "trash";
      bat = "bat --theme=$(defaults read -globalDomain AppleInterfaceStyle &> /dev/null && echo Catppuccin-frappe || echo Catppuccin-latte)";
    };
  };
}
