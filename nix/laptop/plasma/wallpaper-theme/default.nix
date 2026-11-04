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

  regenerateAppThemes = pkgs.writeShellApplication {
    name = "regenerate-app-themes";
    runtimeInputs = with pkgs; [
      matugen
      coreutils
    ];
    text = builtins.readFile ./regenerate-app-themes.sh;
  };

  materialYouColors = pkgs.writeShellApplication {
    name = "material-you-colors";
    runtimeInputs = with pkgs; [
      python3Packages.kde-material-you-colors
      kdePackages.qttools
      kdePackages.plasma-workspace
      coreutils
    ];
    text = ''
      exec kde-material-you-colors \
        --file "''${XDG_CACHE_HOME:-''$HOME/.cache}/wallpaper-theme/image" \
        --dark \
        --disable-konsole \
        --qdbus-executable qdbus \
        --on-change-hook ${regenerateAppThemes}/bin/regenerate-app-themes
    '';
  };
in
{
  home.packages = [
    pkgs.matugen
    pkgs.kdePackages.kdialog
    pkgs.python3Packages.kde-material-you-colors
    wallpaperTheme
    ghosttyReload
    firefoxTheme
    wallpaperChoose
    regenerateAppThemes
    materialYouColors
  ];

  xdg.configFile = {
    "matugen/config.toml".source = ./matugen.toml;
    "matugen/templates".source = ./templates;

    "kde-material-you-colors/config.conf".text = ''
      frame_contrast = 0.05
    '';
  };

  xdg.dataFile."kio/servicemenus/set-wallpaper.desktop".source = ./dolphin-servicemenu.desktop;

  # Long-running daemon: watches the recorded wallpaper state file, applies
  # its Material You color scheme to Plasma (hot-reload safe via the .colors
  # / .colors2 toggle) and runs regenerate-app-themes on start and every
  # wallpaper change.
  systemd.user.services.material-you-colors = {
    Unit = {
      Description = "Material You color daemon for Plasma";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${materialYouColors}/bin/material-you-colors";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
