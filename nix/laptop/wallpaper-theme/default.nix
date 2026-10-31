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
      systemd
      firefoxTheme
    ];
    text = builtins.readFile ./wallpaper-theme.sh;
  };

  firefoxTheme = pkgs.writeShellApplication {
    name = "firefox-theme";
    runtimeInputs = with pkgs; [
      procps
      coreutils
    ];
    text = builtins.readFile ./firefox-theme.sh;
  };

  wallpaperChoose = pkgs.writeShellApplication {
    name = "wallpaper-choose";
    runtimeInputs = with pkgs; [
      kdePackages.kdialog
      wallpaperTheme
    ];
    text = builtins.readFile ./wallpaper-choose.sh;
  };
in
{
  home.packages = [
    pkgs.matugen
    pkgs.awww
    pkgs.kdePackages.kdialog
    wallpaperTheme
    firefoxTheme
    wallpaperChoose
  ];

  xdg.configFile = {
    "matugen/config.toml".source = ./matugen.toml;
    "matugen/templates".source = ./templates;
  };

  xdg.dataFile."kio/servicemenus/set-wallpaper.desktop".source = ./dolphin-servicemenu.desktop;

  systemd.user.services.awww-daemon = {
    Unit = {
      Description = "Wallpaper daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.awww}/bin/awww-daemon";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.wallpaper-theme = {
    Unit = {
      Description = "Regenerate colors from the last wallpaper";
      PartOf = [
        "graphical-session.target"
        "awww-daemon.service"
      ];
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
