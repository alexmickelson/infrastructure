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
      # function codex
      #   docker run --rm -it \
      #     -u node \
      #     -e HOME=/home/node \
      #     -v "$PWD:/workspace" \
      #     -v "$HOME/.codex:/home/node/.codex" \
      #     -w /workspace \
      #     node:22-bookworm \
      #     bash -lc '
      #       npm install -g --prefix "$HOME/.local" @openai/codex &&
      #       export PATH="$HOME/.local/bin:$PATH" &&
      #       exec codex
      #     '
      # end
    appendConfig = ''

      function k --wraps kubectl --description "Alias for kubectl"
        kubectl $argv
      end
      complete -c k -w kubectl
      
    '';
  };

  home.username = "alexm";
  home.homeDirectory = "/home/alexm";
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [ "electron-39.8.10" ];
  };
  home.packages = with pkgs; [
    k9s
    jwt-cli
    fish
    kubectl
    pv
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
    yq
    # ghostty
    nixgl.nixGLIntel
    (config.lib.nixGL.wrap ghostty)
    wl-clipboard
    jellyfin-tui
    bluetui
    #nixfmt-classic
    opencodeFlake.packages.${pkgs.stdenv.hostPlatform.system}.opencode
    monitorTuiFlake.packages.${pkgs.stdenv.hostPlatform.system}.default
    (config.lib.nixGL.wrap zenBrowserFlake.packages.${pkgs.stdenv.hostPlatform.system}.default)
    bitwarden-desktop
    wiremix
    (config.lib.nixGL.wrap moonlight-qt)
    nvtopPackages.amd
    argocd
    # jan
    # texlivePackages.jetbrainsmono-otf
    # nerd-fonts.fira-code
    # dejavu_fonts
    # vscode-fhs
    # aider-chat-full

    codex
    # elixir
    # elixir-ls
    # beamMinimal28Packages.elixir_1_19
    # beamMinimal28Packages.elixir-ls
    beamMinimal28Packages.erlang
    beamMinimal28Packages.elixir_1_19
    beamMinimal28Packages.expert
    inotify-tools
    watchman
    
    # pi-coding-agent
    ripgrep
  ];
  fonts.fontconfig.enable = true;
  programs.firefox = {
    enable = true;
    package = config.lib.nixGL.wrap pkgs.firefox;
    configPath = "${config.xdg.configHome}/mozilla/firefox";
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

    ".scripts/record-transcribe-wrapper.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Run the record-transcribe script in ghostty.
        NIXGL="$(command -v nixGLIntel 2>/dev/null || true)"
        if [[ -z "$NIXGL" ]]; then
          export PATH="$HOME/.nix-profile/bin:$PATH"
          NIXGL="$(command -v nixGLIntel 2>/dev/null || true)"
        fi
        if [[ -n "$NIXGL" ]]; then
          exec "$NIXGL" ghostty -e /home/alexm/projects/infrastructure/record-transcribe.sh
        else
          echo "nixGLIntel not found, running without GPU wrapper."
          exec ghostty -e /home/alexm/projects/infrastructure/record-transcribe.sh
        fi
      '';
    };
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
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
      ];
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" =
      {
        name = "Launch Ghostty";
        command = "nixGL ghostty";
        binding = "<Super>t";
      };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" =
      {
        name = "Record and transcribe";
        command = "${config.home.homeDirectory}/.scripts/record-transcribe-wrapper.sh";
        binding = "<Super>space";
      };
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    gtk4.theme = null;
  };
  programs.home-manager.enable = true;
}
