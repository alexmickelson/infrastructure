{ pkgs, ... }: 
{
  home.packages = with pkgs; [
    vscode-fhs
    gnome-software
    gnome-tweaks
    # nvtopPackages.nvidia
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    # fira-code
    # (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
    kubernetes-helm
    busybox
    ghostty
    elixir_1_18
    inotify-tools # needed for elixir hot-reloading
    nodejs_24
    pnpm
    legcord
    ffmpeg
    gh
    bitwarden-desktop
    jellyfin-tui
    bluetui
    nexusmods-app-unfree
  ];

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