{
  pkgs,
  ...
}:

{
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
  services.displayManager.defaultSession = "gnome";

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };

  environment.systemPackages = with pkgs; [
    kitty
    libnotify
    cliphist
    wl-clip-persist
    wl-clipboard
    grim
    slurp
    grimblast
    swayosd
    hyprpicker
    brightnessctl
    playerctl
    pavucontrol
    networkmanagerapplet
    blueman
  ];
}
