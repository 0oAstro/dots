{
  username,
  ...
}:
###################################################################################
#
#  macOS's System configuration
#
#  All the configuration options are documented here:
#    https://daiderd.com/nix-darwin/manual/index.html#sec-options
#  Incomplete list of macOS `defaults` commands :
#    https://github.com/yannbertrand/macos-defaults
#
###################################################################################
{
  ids.gids.nixbld = 30000;

  system = {
    # activationScripts are executed every time you boot the system or run `nixos-rebuild` / `darwin-rebuild`.
    activationScripts.postUserActivation.text = ''
      # activateSettings -u will reload the settings from the database and apply them to the current session,
      # so we do not need to logout and login again to make the changes take effect.
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';

    startup.chime = false; # disable startup sound

    defaults = {
      # menuExtraClock.Show24Hour = true;  # show 24 hour clock

      # customize dock
      dock = {
        autohide = false;
        show-recents = false; # disable recent apps
        enable-spring-load-actions-on-all-items = true;
        expose-group-apps = true;
        magnification = true;
        minimize-to-application = true;
        mouse-over-hilite-stack = true;
        persistent-apps = [
          { app = "/Applications/1Password.app"; }
          { app = "/Applications/Spotify.app"; }
          { app = "/Applications/Obsidian.app"; }
          { app = "/Applications/Notion.app"; }
          { app = "/Applications/Brave Browser Nightly.app"; }
          { app = "/Applications/Zed Preview.app"; }
          { app = "/Applications/Cursor.app"; }
          { app = "/Applications/Ghostty.app"; }
          { app = "/System/Applications/Mail.app"; }
          { app = "/Applications/WhatsApp.app"; }
          { app = "/Applications/Vesktop.app"; }
        ];
        scroll-to-open = true;
        showhidden = true;

        # 1: Disabled
        # 2: Mission Control
        # 3: Application Windows
        # 4: Desktop
        # 5: Start Screen Saver
        # 6: Disable Screen Saver
        # 7: Dashboard
        # 10: Put Display to Sleep
        # 11: Launchpad
        # 12: Notification Center
        # 13: Lock Screen
        # 14: Quick Note

        wvous-tl-corner = 1; # top-left
        wvous-tr-corner = 1; # top-right
        wvous-bl-corner = 1; # bottom-left
        wvous-br-corner = 1; # bottom-right
      };

      # customize finder
      finder = {
        _FXShowPosixPathInTitle = true; # show full path in finder title
        FXEnableExtensionChangeWarning = false; # disable warning when changing file extension
        QuitMenuItem = false; # enable quit menu item
        ShowPathbar = true; # show path bar
        ShowStatusBar = true; # show status bar
        CreateDesktop = true; # disable desktop icons
        FXDefaultSearchScope = "SCcf"; # When performing a search, search the current folder by default
        FXPreferredViewStyle = "clmv"; # set default view style to icon view
      };

      # customize trackpad
      trackpad = {
        ActuationStrength = 0; # light click
        Clicking = true; # enable tap to click
        Dragging = false;
        TrackpadThreeFingerDrag = false; # enable three finger drag
        TrackpadRightClick = true; # enable right click
        FirstClickThreshold = 0; # light touch
        SecondClickThreshold = 2; # firm touch
      };

      # customize settings that not supported by nix-darwin directly
      # Incomplete list of macOS `defaults` commands :
      #   https://github.com/yannbertrand/macos-defaults
      NSGlobalDomain = {
        # `defaults read NSGlobalDomain "xxx"`
        "com.apple.sound.beep.feedback" = 0; # disable beep sound when pressing volume up/down key
        AppleKeyboardUIMode = 3; # Mode 3 enables full keyboard control.
        ApplePressAndHoldEnabled = false; # we use vim

        # If you press and hold certain keyboard keys when in a text area, the key’s character begins to repeat.
        # This is very useful for vim users, they use `hjkl` to move cursor.
        # sets how long it takes before it starts repeating.
        InitialKeyRepeat = 15; # normal minimum is 15 (225 ms), maximum is 120 (1800 ms)
        # sets how fast it repeats once it starts.
        KeyRepeat = 2; # normal minimum is 2 (30 ms), maximum is 120 (1800 ms)

        NSAutomaticCapitalizationEnabled = false; # disable auto capitalization(自动大写)
        NSAutomaticDashSubstitutionEnabled = false; # disable auto dash substitution(智能破折号替换)
        NSAutomaticPeriodSubstitutionEnabled = true; # enable auto period substitution(智能句号替换)
        NSAutomaticQuoteSubstitutionEnabled = false; # disable auto quote substitution(智能引号替换)
        NSAutomaticSpellingCorrectionEnabled = false; # disable auto spelling correction(自动拼写检查)
        NSNavPanelExpandedStateForSaveMode = true; # expand save panel by default(保存文件时的路径选择/文件名输入页)
        NSNavPanelExpandedStateForSaveMode2 = true;
      };

      # Customize settings that not supported by nix-darwin directly
      # see the source code of this project to get more undocumented options:
      #    https://github.com/rgcr/m-cli
      #
      # All custom entries can be found by running `defaults read` command.
      # or `defaults read xxx` to read a specific domain.
      CustomUserPreferences = {
        ".GlobalPreferences" = {
          # automatically switch to a new space when switching to the application
          AppleSpacesSwitchOnActivate = true;
        };
        NSGlobalDomain = {
          # Add a context menu item for showing the Web Inspector in web views
          WebKitDeveloperExtras = true;
        };
        "com.apple.finder" = {
          ShowExternalHardDrivesOnDesktop = true;
          ShowHardDrivesOnDesktop = true;
          ShowMountedServersOnDesktop = true;
          ShowRemovableMediaOnDesktop = true;
          _FXSortFoldersFirst = true;
        };
        "com.apple.desktopservices" = {
          # Avoid creating .DS_Store files on network or USB volumes
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = false;
        };
        "com.apple.spaces" = {
          "spans-displays" = 0; # Display have seperate spaces
        };
        "com.apple.WindowManager" = {
          StandardHideDesktopIcons = 1; # Hide items on desktop
          HideDesktop = 0; # Hide items on desktop & stage manager
          StageManagerHideWidgets = 0;
          StandardHideWidgets = 0;
        };
        "com.apple.screensaver" = {
          askForPassword = 1;
          askForPasswordDelay = 0;
        };
        "com.apple.screencapture" = {
          location = "/Users/${username}/Dropbox/Screenshots";
          type = "png";
        };
        "com.apple.AdLib" = {
          allowApplePersonalizedAdvertising = false;
        };
        # Prevent Photos from opening automatically when devices are plugged in
        "com.apple.ImageCapture".disableHotPlug = true;
        # dock folders with correst sort order
        # PR: https://github.com/LnL7/nix-darwin/pull/1004
        "com.apple.dock" = {
          persistent-others = [
            {
              "tile-data" = {
                "file-data" = {
                  "_CFURLString" = "/Users/${username}/Downloads";
                  "_CFURLStringType" = 0;
                };
                "arrangement" = 2; # sorting order
                "displayas" = 1;
                "showas" = 2;
              };
              "tile-type" = "directory-tile";
            }
            {
              "tile-data" = {
                "file-data" = {
                  "_CFURLString" = "/Users/${username}/Dropbox/Screenshots";
                  "_CFURLStringType" = 0;
                };
                "arrangement" = 2;
                "displayas" = 1;
                "showas" = 2;
              };
              "tile-type" = "directory-tile";
            }
          ];
        };
      };

      loginwindow = {
        GuestEnabled = false; # disable guest user
        SHOWFULLNAME = false; # show full name in login window
      };
    };

    stateVersion = 5; # nix-darwin state version
  };

  # Add ability to used TouchID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;
}
