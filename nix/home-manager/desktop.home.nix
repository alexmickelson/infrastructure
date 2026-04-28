{ pkgs, ... }: 
{
  home.packages = with pkgs; [
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
    jellyfin-tui
    bluetui

    lazydocker
    
    elixir
    elixir-ls
    inotify-tools
    watchman
  ];

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