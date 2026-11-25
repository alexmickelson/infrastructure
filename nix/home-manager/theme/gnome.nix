{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.wallpaperTheme.gnome;

  wallpaperApplyGnome = pkgs.writeShellApplication {
    name = "wallpaper-apply-gnome";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gawk
      pkgs.glib
      pkgs.gnused
    ];
    text = builtins.readFile ./wallpaper-apply-gnome.sh;
  };
in
{
  options.wallpaperTheme.gnome = {
    enable = lib.mkEnableOption "applying the wallpaper and accent color on GNOME";
  };

  config = lib.mkIf (config.wallpaperTheme.enable && cfg.enable) {
    home.packages = [ wallpaperApplyGnome ];

    xdg.dataFile."nautilus/scripts/Set Wallpaper" = {
      executable = true;
      text = builtins.readFile ./nautilus-set-wallpaper.sh;
    };
  };
}
