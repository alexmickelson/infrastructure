{
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./inputactions.nix
    ./quickshell
    ./wallpaper-theme
    ./waybar
  ];

  programs.plasma = {
    enable = true;

    kwin.virtualDesktops.number = 10;

    # inputactions kwin plugin: kwin does not auto-load it, and the effect is
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
      } // (lib.listToAttrs (
        map (i: {
          name = "Switch to Desktop ${toString i}";
          value = "Meta+${if i == 10 then "0" else toString i}";
        }) (lib.range 1 10)
      )) // (lib.listToAttrs (
        map (i: {
          name = "Move Window to Desktop ${toString i}";
          value = "Meta+Shift+${if i == 10 then "0" else toString i}";
        }) (lib.range 1 10)
      ));

      "services/com.mitchellh.Ghostty.desktop" = {
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
