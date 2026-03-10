{ pkgs, ... }: 
{
  imports = [ ./fish.home.nix ];

  customFish = {
    bluetuiAliases = true;
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
    makemkv
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
  ];
  programs.direnv = {
    enable = true;
  };
  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
  };
  home.sessionVariables = {
    EDITOR = "vim";
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
    lockFavorites: false
    '';
  };
}