{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.wallpaperTheme.cosmic;

  wallpaperFollowCosmic = pkgs.writeShellApplication {
    name = "wallpaper-follow-cosmic";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnused
      pkgs.inotify-tools
      pkgs.systemd
    ];
    text = builtins.readFile ./wallpaper-follow-cosmic.sh;
  };
in
{
  options.wallpaperTheme.cosmic = {
    enable = lib.mkEnableOption "following the wallpaper chosen in COSMIC settings";
  };

  config = lib.mkIf (config.wallpaperTheme.enable && cfg.enable) {
    home.packages = [ wallpaperFollowCosmic ];

    systemd.user.services.wallpaper-follow-cosmic = {
      Unit = {
        Description = "Follow the wallpaper chosen in COSMIC settings";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${wallpaperFollowCosmic}/bin/wallpaper-follow-cosmic";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
