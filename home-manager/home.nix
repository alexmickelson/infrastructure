{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "alexm";
  home.homeDirectory = "/home/alexm";

  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  home.packages = [
    pkgs.openldap
    pkgs.k9s
    pkgs.jwt-cli
    pkgs.thefuck
    pkgs.fish
    pkgs.kubectl
    pkgs.lazydocker
  ];
  programs.fish = {
    enable = true;
    shellAliases = {
      dang="fuck";
    };
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

thefuck --alias | source
   '';
  };
  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
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

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/alexm/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "vim";
  };
  dconf.enable = true;
  dconf.settings = {
    "org/gnome/desktop/wm/keybindings" = {
      toggle-maximized=["<Super>m"];
    };
  };
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
