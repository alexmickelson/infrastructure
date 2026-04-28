{ config, pkgs, ... }:

let
  opencodeFlake = builtins.getFlake (toString ../flakes/opencode);
  monitorTuiFlake = builtins.getFlake (toString ../../monitors/monitor-tui-rs);
  zenBrowserFlake = builtins.getFlake "github:youwen5/zen-browser-flake";
  nixgl = import
    (fetchTarball "https://github.com/nix-community/nixGL/archive/main.tar.gz")
    { };
in {
  imports = [ ./fish.home.nix ];

  customFish = {
    bluetuiAliases = true;
    dotnetPackage = with pkgs.dotnetCorePackages; combinePackages [ sdk_8_0 sdk_9_0 ];
    bitwardenSshAgent = true;
  };

  home.username = "alexm";
  home.homeDirectory = "/home/alexm";
  nixpkgs.config.allowUnfree = true;
  home.packages = with pkgs; [
    k9s
    jwt-cli
    fish
    kubectl
    # (lazydocker.overrideAttrs (oldAttrs: rec {
    #   version = "0.24.4";
    #   src = pkgs.fetchFromGitHub {
    #     owner = "jesseduffield";
    #     repo = "lazydocker";
    #     rev = "v${version}";
    #     hash = "sha256-cW90/yblSLBkcR4ZdtcSI9MXFjOUxyEectjRn9vZwvg=";
    #   };
    # }))
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
    opencodeFlake.packages.${pkgs.stdenv.hostPlatform.system}.opencode
    monitorTuiFlake.packages.${pkgs.stdenv.hostPlatform.system}.default
    (config.lib.nixGL.wrap zenBrowserFlake.packages.${pkgs.stdenv.hostPlatform.system}.default)
    bitwarden-desktop
    wiremix
    (config.lib.nixGL.wrap moonlight-qt)
    nvtopPackages.amd
    # jan
    # texlivePackages.jetbrainsmono-otf
    # nerd-fonts.fira-code
    # dejavu_fonts
    # vscode-fhs
    # aider-chat-full

    codex
    # elixir
    # elixir-ls
    beamMinimal28Packages.elixir_1_19
    beamMinimal28Packages.elixir-ls
    inotify-tools
    watchman
    
  ];
  fonts.fontconfig.enable = true;
  programs.firefox = {
    enable = true;
    package = config.lib.nixGL.wrap pkgs.firefox;
    nativeMessagingHosts = [ pkgs.firefoxpwa ];
  };

  programs.direnv = { enable = true; };
  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      window-inherit-working-directory = "false";
      theme = "Atom";
      font-size = "18";
      window-height = "30";
      window-width = "120"; 
    };
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
    ".local/share/applications/zen-browser.desktop".text = ''
      [Desktop Entry]
      Version=1.0
      Type=Application
      Name=Zen Browser
      Comment=A calmer Firefox-based browser
      Exec=nixGLIntel zen
      Icon=${zenBrowserFlake.packages.${pkgs.stdenv.hostPlatform.system}.default}/share/icons/hicolor/128x128/apps/zen.png
      Terminal=false
      Categories=Network;WebBrowser;
      MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
      StartupWMClass=zen
      Actions=new-window;new-private-window;

      [Desktop Action new-window]
      Name=Open a New Window
      Exec=nixGLIntel zen --new-window

      [Desktop Action new-private-window]
      Name=Open a New Private Window
      Exec=nixGLIntel zen --private-window
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
    gtk4.theme = config.gtk.theme;
  };
  programs.home-manager.enable = true;
}
