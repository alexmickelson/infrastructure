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
    k9s
    jwt-cli
    fish
    kubectl
    lazydocker
    traceroute
    (with dotnetCorePackages; combinePackages [ sdk_8_0 sdk_9_0 ])
    nodejs_22
    parallel
    #k0sctl
    kubernetes-helm
    ffmpeg
    pnpm
    jq
    # rustup
    # lldb
    nmap
    iperf
    #makemkv
    #elixir_1_18
    #inotify-tools
    # gnome-themes-extra
    uv
    ghostty
    nixgl.nixGLIntel
    (config.lib.nixGL.wrap ghostty)
    wl-clipboard
    jellyfin-tui
    firefoxpwa
    bluetui
    #nixfmt-classic
    opencodeFlake.packages.${system}.opencode
    # jan
    # texlivePackages.jetbrainsmono-otf
    # nerd-fonts.fira-code
    # dejavu_fonts
    # vscode-fhs
    # aider-chat-full
  ];
  fonts.fontconfig.enable = true;
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
      alias jelly="jellyfin-tui"

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
    "org/gnome/desktop/wm/keybindings" = {
      toggle-maximized = [ "<Super>m" ];
    };
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
