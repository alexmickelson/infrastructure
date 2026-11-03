{
  pkgs,
  ...
}:
let
  wallpaperTheme = pkgs.writeShellApplication {
    name = "wallpaper-theme";
    runtimeInputs = with pkgs; [
      matugen
      kdePackages.plasma-workspace
      procps
    ];
    text = builtins.readFile ./wallpaper-theme.sh;
  };

  ghosttyReload = pkgs.writeShellApplication {
    name = "ghostty-reload";
    runtimeInputs = with pkgs; [
      procps
      coreutils
    ];
    text = builtins.readFile ./ghostty-reload.sh;
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
    pkgs.kdePackages.kdialog
    wallpaperTheme
    ghosttyReload
    firefoxTheme
    wallpaperChoose
  ];

  xdg.configFile = {
    "matugen/config.toml".source = ./matugen.toml;
    "matugen/templates".source = ./templates;
  };

  xdg.dataFile."kio/servicemenus/set-wallpaper.desktop".source = ./dolphin-servicemenu.desktop;

  systemd.user.services.wallpaper-theme = {
    Unit = {
      Description = "Regenerate colors from the last wallpaper";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${wallpaperTheme}/bin/wallpaper-theme";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
