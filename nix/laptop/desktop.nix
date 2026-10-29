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

  programs.hyprland = {
    enable = isHyprland;
    withUWSM = isHyprland;
    xwayland.enable = true;
  };

  services.desktopManager.gnome.enable = isGnome;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };

  systemd.user.services.hyprpolkitagent = lib.mkIf isHyprland {
    description = "Hyprland PolicyKit authentication agent";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.hyprpolkitagent}/bin/hyprpolkitagent";
      Restart = "on-failure";
    };
  };

  xdg.portal = {
    extraPortals =
      lib.optionals isHyprland [ pkgs.xdg-desktop-portal-gtk ]
      ++ lib.optionals isGnome [ pkgs.xdg-desktop-portal-gnome ];
    config.common.default = lib.mkIf isGnome [ "gnome" ];
  };

  environment.systemPackages =
    lib.optionals isHyprland (
      with pkgs;
      [
        hyprpaper
        hypridle
        hyprlock
        waybar
        wofi
        grim
        slurp
        wl-clipboard
        playerctl
        brightnessctl
        pavucontrol
        networkmanagerapplet
      ]
    )
    ++ lib.optionals isGnome (
      with pkgs;
      [
        gnome-software
        gnome-tweaks
        xdg-desktop-portal-gnome
      ]
    );
}
