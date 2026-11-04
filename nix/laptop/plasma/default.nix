{
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./input_actions.nix
    ./quickshell
    ./wallpaper-theme
    ./waybar
  ];

  programs.plasma = {
    enable = true;

    kwin.virtualDesktops.number = 10;

    # input-actions kwin plugin: kwin does not auto-load it, and the effect is
    # off by default (also loadable via Desktop Effects or
    # `qdbus org.kde.KWin /Effects loadEffect kwin_gestures`)
    configFile.kwinrc.Plugins."kwin_gesturesEnabled" = true;

    startup.desktopScript."remove-panels" = {
      text = "panels().forEach((panel) => panel.remove());";
      priority = 2;
    };

    shortcuts = {
      kwin = {
        "Window Close" = "Meta+C";
        "Edit Tiles" = "Meta+Shift+T";
      };

      "services/com.mitchellh.ghostty.desktop" = {
        _launch = "Meta+T";
      };

      "services/org.kde.dolphin.desktop" = {
        _launch = "Meta+E";
      };
    };
  };

  xdg.configFile."autostart/nm-applet.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Network Manager Applet
    Exec=${pkgs.networkmanagerapplet}/bin/nm-applet
    Terminal=false
  '';

  xdg.configFile."autostart/blueman-applet.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Blueman Applet
    Exec=${pkgs.blueman}/bin/blueman-applet
    Terminal=false
  '';
}
