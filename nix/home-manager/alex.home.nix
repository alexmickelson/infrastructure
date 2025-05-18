{ pkgs, ... }: 
{
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
  ];
  home.sessionVariables = {
    EDITOR = "vim";
  };
  programs.fish = {
    enable = true;
    shellInit = ''
function commit
  git add --all
  git commit -m "$argv"
  git push
end

# have ctrl+backspace delete previous word
bind \e\[3\;5~ kill-word
# have ctrl+delete delete following word
bind \b  backward-kill-word

set -U fish_user_paths ~/.local/bin $fish_user_paths
#set -U fish_user_paths ~/.dotnet $fish_user_paths
#set -U fish_user_paths ~/.dotnet/tools $fish_user_paths

export VISUAL=vim
export EDITOR="$VISUAL"
export DOTNET_WATCH_RESTART_ON_RUDE_EDIT=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1
set -x LIBVIRT_DEFAULT_URI qemu:///system
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
    lockFavorites: false
    '';
  };
}