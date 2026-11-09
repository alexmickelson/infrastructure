{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.wallpaperTheme;

  mkApp =
    name: script: runtimeInputs:
    pkgs.writeShellApplication {
      inherit name runtimeInputs;
      text = builtins.readFile script;
    };

  withWallpaperDir = text: ''
    export WALLPAPER_DIR=${lib.escapeShellArg cfg.wallpaperDir}
    ${text}
  '';

  ghosttyReload = mkApp "ghostty-reload" ./ghostty-reload.sh [ pkgs.procps ];
  firefoxTheme = mkApp "firefox-theme" ./firefox-theme.sh [
    pkgs.coreutils
    pkgs.procps
  ];

  regenerateAppThemes = mkApp "regenerate-app-themes" ./regenerate-app-themes.sh [
    pkgs.coreutils
    pkgs.matugen
    ghosttyReload
    firefoxTheme
  ];

  wallpaperApply = mkApp "wallpaper-apply" ./wallpaper-apply.sh [ pkgs.coreutils ];

  wallpaperTheme = pkgs.writeShellApplication {
    name = "wallpaper-theme";
    runtimeInputs = [
      pkgs.coreutils
      regenerateAppThemes
      wallpaperApply
    ];
    text = withWallpaperDir (builtins.readFile ./wallpaper-theme.sh);
  };

  wallpaperChoose = pkgs.writeShellApplication {
    name = "wallpaper-choose";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.zenity
      wallpaperTheme
    ];
    text = withWallpaperDir (builtins.readFile ./wallpaper-choose.sh);
  };
in
{
  imports = [
    ./gnome.nix
    ./kde.nix
  ];

  options.wallpaperTheme = {
    enable = lib.mkEnableOption "wallpaper-driven theming across desktops";

    wallpaperDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/Documents/wallpaper";
      description = "Directory searched when wallpaper-theme is given a bare filename.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.matugen
      ghosttyReload
      firefoxTheme
      regenerateAppThemes
      wallpaperApply
      wallpaperTheme
      wallpaperChoose
    ];

    xdg.configFile = {
      "matugen/config.toml".source = ./matugen.toml;
      "matugen/templates".source = ./templates;
    };

    systemd.user.services.wallpaper-theme = {
      Unit = {
        Description = "Apply the recorded wallpaper and generated theme";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${wallpaperTheme}/bin/wallpaper-theme";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
