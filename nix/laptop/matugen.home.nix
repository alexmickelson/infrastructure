{ pkgs, ... }:
let
  wallpaperTheme = pkgs.writeShellApplication {
    name = "wallpaper-theme";
    runtimeInputs = with pkgs; [
      matugen
      awww
      procps
      hyprland
      mako
      glib
      dbus
    ];
    text = builtins.readFile ./matugen/wallpaper-theme.sh;
  };
in
{
  home.packages = [
    pkgs.matugen
    pkgs.awww
    wallpaperTheme
  ];

  xdg.configFile = {
    "matugen/config.toml".source = ./matugen/config.toml;
    "matugen/templates".source = ./matugen/templates;
  };

  systemd.user.services.awww-daemon = {
    Unit = {
      Description = "Wallpaper daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.awww}/bin/awww-daemon";
      Restart = "always";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.wallpaper-theme = {
    Unit = {
      Description = "Regenerate colors from the last wallpaper";
      PartOf = [ "graphical-session.target" ];
      After = [
        "graphical-session.target"
        "awww-daemon.service"
      ];
      Wants = [ "awww-daemon.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${wallpaperTheme}/bin/wallpaper-theme";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
