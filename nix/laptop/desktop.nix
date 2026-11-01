{
  desktop,
  pkgs,
  lib,
  ...
}:

let
  isHyprland = desktop == "hyprland";
  isGnome = desktop == "gnome";
in
{
  imports = lib.optional isHyprland ./hyprland/system.nix;

  assertions = [
    {
      assertion = isHyprland || isGnome;
      message = "desktop must be either \"hyprland\" or \"gnome\"";
    }
  ];

  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  services.displayManager = {
    gdm.enable = true;
    defaultSession = if isHyprland then "hyprland-uwsm" else "gnome";
  };

  qt = {
    enable = true;
    platformTheme = "kde";
    style = "breeze";
  };

  services.desktopManager.gnome.enable = isGnome;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };

  xdg.portal = {
    extraPortals = lib.optional isGnome pkgs.xdg-desktop-portal-gnome;
    config.common.default = lib.mkIf isGnome [ "gnome" ];
  };

  environment.systemPackages =
    lib.optionals isGnome (
      with pkgs;
      [
        gnome-software
        gnome-tweaks
        xdg-desktop-portal-gnome
      ]
    );
}
