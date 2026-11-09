{
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./input_actions.nix
    ./quickshell
    ./waybar
  ];

  programs.plasma = {
    enable = true;

    kwin.virtualDesktops.number = 10;

    # input-actions kwin plugin: kwin does not auto-load it, and the effect is
    # off by default (also loadable via Desktop Effects or
    # `qdbus org.kde.KWin /Effects loadEffect kwin_gestures`)
    configFile = {
      kwinrc = {
        Plugins."kwin_gesturesEnabled" = true;
        Plugins."zoomEnabled" = false;

        "org.kde.kdecoration2" = {
          Library = "org.kde.klassy";
          Theme = "Klassy";
        };
      };

      "klassy/klassyrc" = {
        Global.LookAndFeelSet = "org.kde.breezedark.desktop";
        Style.SplitterProxyEnabled = true;
        TitleBarOpacity.ActiveTitleBarOpacity = 90;
        TitleBarOpacity.InactiveTitleBarOpacity = 90;
        TitleBarOpacity.ApplyOpacityToHeader = false;
        TitleBarOpacity.BlurTransparentTitleBars = false;
        Windeco.DrawTitleBarSeparator = false;
        Windeco.MatchTitleBarToApplicationColor = true;
        Windeco.WindowCornerRadius = 15;
        WindowOutlineStyle.WindowOutlineStyleActive = "WindowOutlineAccentColor";
        WindowOutlineStyle.WindowOutlineAccentColorOpacityActive = 40;
      };
    };

    startup.desktopScript."remove-panels" = {
      text = "panels().forEach((panel) => panel.remove());";
      priority = 2;
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
