{ pkgs, ... }: 
{
  home.packages = with pkgs; [
    vscode-fhs
    gnome-software
    gnome-tweaks
    nvtopPackages.nvidia
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    # fira-code
    # (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
    kubernetes-helm
    busybox
    ghostty
    elixir_1_18
    inotify-tools # needed for elixir hot-reloading
    # nodejs_23
    pnpm
  ];

  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
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
}