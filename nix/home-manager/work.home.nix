{ config, pkgs, ... }:

let
  opencodeFlake = builtins.getFlake (toString ../flakes/opencode);
  nixgl = import
    (fetchTarball "https://github.com/nix-community/nixGL/archive/main.tar.gz")
    { };
in {
  home.username = "alexm";
  home.homeDirectory = "/home/alexm";
  nixpkgs.config.allowUnfree = true;
  home.packages = with pkgs; [
    openldap
    k9s
    jwt-cli
    fish
    kubectl
    lazydocker
    traceroute
    (with dotnetCorePackages; combinePackages [ sdk_8_0 sdk_9_0 ])
    nodejs_22
    parallel
    k0sctl
    kubernetes-helm
    ffmpeg
    pnpm
    jq
    # rustup
    # lldb
    nmap
    iperf
    makemkv
    elixir_1_18
    inotify-tools
    # gnome-themes-extra
    uv
    ghostty
    nixgl.nixGLIntel
    (config.lib.nixGL.wrap ghostty)
    wl-clipboard
    jellyfin-tui
    firefoxpwa
    bluetui
    nixfmt-classic
    opencodeFlake.packages.${system}.opencode
  ];

  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
    nativeMessagingHosts = [ pkgs.firefoxpwa ];
  };

  programs.direnv = { enable = true; };
  programs.ghostty = { enable = true; };
  programs.fish = {
    enable = true;
    shellInit = ''
      # https://gist.github.com/thomd/7667642
      export LS_COLORS=':di=95'

      function commit
        git add --all
        git commit -m "$argv"
        git pull
        git push
      end

      # have ctrl+backspace delete previous word
      bind \e\[3\;5~ kill-word
      # have ctrl+delete delete following word
      bind \b  backward-kill-word

      alias blue="bluetui"

      set -U fish_user_paths ~/.local/bin $fish_user_paths
      set -U fish_user_paths ~/bin $fish_user_paths
      set -U fish_user_paths ~/.dotnet $fish_user_paths
      set -U fish_user_paths ~/.dotnet/tools $fish_user_paths
      set fish_pager_color_selected_background --background='00399c'

      export VISUAL=vim
      export EDITOR="$VISUAL"
      export DOTNET_WATCH_RESTART_ON_RUDE_EDIT=1
      export DOTNET_CLI_TELEMETRY_OPTOUT=1
      export DOTNET_ROOT=${pkgs.dotnetCorePackages.sdk_8_0}

      set -x LIBVIRT_DEFAULT_URI qemu:///system
      set -x TERM xterm-256color # ghostty

      # https://github.com/DevAtDawn/gh-fish/blob/main/gh-copilot-alias.fish
      function ghcs
          set -l FUNCNAME (status function)
          set -l TARGET "shell"
          set -l GH_DEBUG "$GH_DEBUG"
          set -l GH_HOST "$GH_HOST"
          set -l __USAGE "
      Wrapper around \`gh copilot suggest\` to suggest a command based on a natural language description of the desired output effort.
      Supports executing suggested commands if applicable.
      USAGE
        $FUNCNAME [flags] <prompt>
      FLAGS
        -d, --debug           Enable debugging
        -h, --help            Display help usage
            --hostname        The GitHub host to use for authentication
        -t, --target target   Target for suggestion; must be shell, gh, git
                              default: \"$TARGET\"
      EXAMPLES
      - Guided experience
        $FUNCNAME
      - Git use cases
        $FUNCNAME -t git \"Undo the most recent local commits\"
        $FUNCNAME -t git \"Clean up local branches\"
        $FUNCNAME -t git \"Setup LFS for images\"
      - Working with the GitHub CLI in the terminal
        $FUNCNAME -t gh \"Create pull request\"
        $FUNCNAME -t gh \"List pull requests waiting for my review\"
        $FUNCNAME -t gh \"Summarize work I have done in issues and pull requests for promotion\"
      - General use cases
        $FUNCNAME \"Kill processes holding onto deleted files\"
        $FUNCNAME \"Test whether there are SSL/TLS issues with github.com\"
        $FUNCNAME \"Convert SVG to PNG and resize\"
        $FUNCNAME \"Convert MOV to animated PNG\"
      "

          set -l argv_copy $argv
          for i in (seq (count $argv_copy))
              switch $argv_copy[$i]
                  case '-d' '--debug'
                      set -l GH_DEBUG "api"
                  case '-h' '--help'
                      echo "$__USAGE"
                      return 0
                  case '--hostname'
                      set -l GH_HOST $argv_copy[(math $i + 1)]
                      set -e argv_copy[(math $i + 1)]
                  case '-t' '--target'
                      set -l TARGET $argv_copy[(math $i + 1)]
                      set -e argv_copy[(math $i + 1)]
              end
          end

          set -e argv_copy[1..(math $i - 1)]

          set -l TMPFILE (mktemp -t gh-copilotXXXXXX)
          function cleanup
              rm -f "$TMPFILE"
          end
          trap cleanup EXIT

          if env GH_DEBUG="$GH_DEBUG" GH_HOST="$GH_HOST" gh copilot suggest -t "$TARGET" $argv_copy --shell-out "$TMPFILE"
              if test -s "$TMPFILE"
                  set -l FIXED_CMD (cat $TMPFILE)
                  history --merge --save -- $FIXED_CMD
                  echo
                  eval $FIXED_CMD
              end
          else
              return 1
          end
      end


      function plz
        ghcs suggest "$argv"
      end
    '';
  };
  home.file = {
    ".config/lazydocker/config.yml".text = ''
      gui:
        returnImmediately: true
        screenMode: "half"
    '';
    ".config/k9s/config.yaml".text = ''
      k9s:
        liveViewAutoRefresh: true
        screenDumpDir: /home/alexm/.local/state/k9s/screen-dumps
        refreshRate: 2
        maxConnRetry: 5
        readOnly: false
        noExitOnCtrlC: false
        ui:
          enableMouse: false
          headless: false
          logoless: false
          crumbsless: false
          reactive: false
          noIcons: false
          defaultsToFullScreen: false
        skipLatestRevCheck: false
        disablePodCounting: false
        shellPod:
          image: busybox:1.35.0
          namespace: default
          limits:
            cpu: 100m
            memory: 100Mi
        imageScans:
          enable: false
          exclusions:
            namespaces: []
            labels: {}
        logger:
          tail: 1000
          buffer: 5000
          sinceSeconds: -1
          textWrap: false
          showTime: false
        thresholds:
          cpu:
            critical: 90
            warn: 70
          memory:
            critical: 90
            warn: 70
        namespace:
          lockFavorites: false'';

    ".local/share/applications/firefox.desktop".text = ''
      [Desktop Entry]
      Version=1.0
      Type=Application
      Name=Firefox
      Comment=Browse the Web
      Exec=firefox %u
      Icon=firefox
      Terminal=false
      Categories=Network;WebBrowser;
      MimeType=x-scheme-handler/http;x-scheme-handler/https;text/html;
      StartupWMClass=firefox
      Actions=new-window;new-private-window;

      [Desktop Action new-window]
      Name=Open a New Window
      Exec=firefox --new-window

      [Desktop Action new-private-window]
      Name=Open a New Private Window
      Exec=firefox --private-window
    '';

    ".local/share/applications/teams.desktop".text = ''
      [Desktop Entry]
      Version=1.0
      Type=Application
      Name=Microsoft Teams (Web)
      Comment=Launch Microsoft Teams in Firefox
      Exec=firefox --new-window https://teams.microsoft.com
      Icon=teams
      Terminal=false
      Categories=Network;WebBrowser;
    '';
  };

  home.sessionVariables = { EDITOR = "vim"; };
  dconf.enable = true;
  dconf.settings = {
    "org/gnome/desktop/wm/keybindings" = { toggle-maximized = [ "<Super>m" ]; };
    "org/gnome/desktop/interface" = { color-scheme = "prefer-dark"; };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
      ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" =
      {
        name = "Launch Ghostty";
        command = "nixGL ghostty";
        binding = "<Super>t";
      };
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
  };
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
