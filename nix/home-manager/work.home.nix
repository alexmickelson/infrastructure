{ config, pkgs, ... }:
{
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
    (with dotnetCorePackages; combinePackages [
      sdk_8_0
      sdk_9_0
    ])
    nodejs_22
    parallel
    k0sctl
    kubernetes-helm
    ffmpeg
    pnpm
    jq
    rustup
    lldb
    nmap
    iperf
    makemkv
  ];
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
   '';
  };
  home.file = {
   
    ".config/lazydocker/config.yml".text = ''
gui:
  returnImmediately: true
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

  home.sessionVariables = {
    EDITOR = "vim";
  };
  dconf.enable = true;
  dconf.settings = {
    "org/gnome/desktop/wm/keybindings" = {
      toggle-maximized=["<Super>m"];
    };
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
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
