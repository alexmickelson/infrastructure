{ pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  programs.dms-shell = {
    enable = true;
    enableVPN = false;
    enableDynamicTheming = false;
    enableAudioWavelength = false;
    enableCalendarEvents = false;
  };

  services.displayManager = {
    defaultSession = "hyprland-uwsm";
    autoLogin = {
      enable = true;
      user = "alex";
    };
    dms-greeter = {
      enable = true;
      compositor.name = "hyprland";
    };
  };

  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  home-manager.users.alex = {
    home.packages = with pkgs; [
      grim
      playerctl
      slurp
      wl-clipboard
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      package = null;
      portalPackage = null;
      configType = "lua";
      systemd.enable = false;
      extraConfig = builtins.readFile ./quickshell/hyprland.lua;
    };

    xdg.configFile."uwsm/env-hyprland".text = ''
      export AQ_DRM_DEVICES=/dev/dri/by-path/pci-0000:01:00.0-card:/dev/dri/by-path/pci-0000:00:01.0-card
      export GBM_BACKEND=nvidia-drm
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
    '';
  };
}
