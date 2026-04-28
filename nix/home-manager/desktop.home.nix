{ pkgs, ... }: 
{
  imports = [ ./fish.home.nix ];

  customFish = {
    bluetuiAliases = true;
    dotnetPackage = with pkgs.dotnetCorePackages; combinePackages [ sdk_8_0 sdk_9_0 ];
    bitwardenSshAgent = true;
  };

  home.packages = with pkgs; [
    k9s
    jwt-cli
    fish
    kubectl
    lazydocker
    btop
    nix-index
    usbutils
    mbuffer
    lzop
    lsof
    code-server
    vim
    htop
    iputils
    dotnetCorePackages.dotnet_9.sdk
    python312
    gcc
    gnumake
    dig
    pciutils
    uv
    bluetui

    vscode-fhs
    gnome-software
    gnome-tweaks
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    kubernetes-helm
    busybox
    ghostty
    nodejs_24
    pnpm
    ffmpeg
    gh
    bitwarden-desktop
    # jellyfin-tui
    bluetui

    lazydocker
    
    elixir
    elixir-ls
    inotify-tools
    watchman
  ];

  programs.direnv = {
    enable = true;
  };
  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      window-inherit-working-directory = "false";
      theme = "Atom";
      font-size = 14;
      window-height = 30;
      window-width = 100; 
    };
  };
  home.sessionVariables = {
    EDITOR = "vim";
  };

  fonts.fontconfig.enable = true;
  dconf.enable = true;
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
    "org/gnome/desktop/wm/keybindings" = {
      toggle-maximized=["<Super>m"];
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Super>t";
      command = "ghostty";
      name = "terminal";
    };
  };
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
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
  screenDumpDir: /home/alex/.local/state/k9s/screen-dumps
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
    lockFavorites: false
    '';
  };
}