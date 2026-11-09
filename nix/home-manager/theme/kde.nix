{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.wallpaperTheme.kde;

  wallpaperApplyPlasma = pkgs.writeShellApplication {
    name = "wallpaper-apply-plasma";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.procps
      pkgs.kdePackages.kconfig
      pkgs.kdePackages.plasma-workspace
    ];
    text = builtins.readFile ./wallpaper-apply-plasma.sh;
  };

  materialYouColors = pkgs.writeShellApplication {
    name = "material-you-colors-kde";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.kde-material-you-colors
      pkgs.kdePackages.qttools
    ];
    text = ''
      if [[ ''${XDG_CURRENT_DESKTOP:-} != *KDE* ]]; then
        exit 0
      fi

      exec kde-material-you-colors \
        --file "''${XDG_CACHE_HOME:-''$HOME/.cache}/wallpaper-theme/image" \
        --dark \
        --disable-konsole \
        --qdbus-executable qdbus
    '';
  };
in
{
  options.wallpaperTheme.kde = {
    enable = lib.mkEnableOption "applying the wallpaper and Material You colors on Plasma";
  };

  config = lib.mkIf (config.wallpaperTheme.enable && cfg.enable) {
    home.packages = [
      pkgs.kdePackages.kdialog
      wallpaperApplyPlasma
      materialYouColors
    ];

    xdg.configFile."kde-material-you-colors/config.conf".text = ''
      [CUSTOM]
      frame_contrast = 0.05
    '';

    xdg.dataFile."kio/servicemenus/set-wallpaper.desktop".source = ./dolphin-servicemenu.desktop;

    systemd.user.services.material-you-colors = {
      Unit = {
        Description = "Material You color daemon for Plasma";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${materialYouColors}/bin/material-you-colors-kde";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
