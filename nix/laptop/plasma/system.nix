{
  pkgs,
  ...
}:
{
  services.desktopManager.plasma6.enable = true;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  powerManagement.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  qt = {
    platformTheme = "kde";
    style = "breeze";
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
