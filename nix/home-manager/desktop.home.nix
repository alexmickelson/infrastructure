{ pkgs, ... }: 
{
  home.packages = with pkgs; [
    vscode-fhs
    gnome-software
    gnome-tweaks
    nvtopPackages.nvidia
    # nerd-fonts.fira-code
    # nerd-fonts.droid-sans-mono
    # fira-code
    (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
    kubernetes-helm
  ];
  fonts.fontconfig.enable = true;
  dconf.enable = true;
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
    "org/gnome/desktop/wm/keybindings" = {
      toggle-maximized=["<Super>m"];
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