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
    gtkCss = lib.mkEnableOption "recoloring GTK and libadwaita apps from the wallpaper";
  };

  config = lib.mkIf (config.wallpaperTheme.enable && cfg.enable) {
    home.packages = [ wallpaperApplyGnome ];

    xdg.dataFile."nautilus/scripts/Set Wallpaper" = {
      executable = true;
      text = builtins.readFile ./nautilus-set-wallpaper.sh;
    };

    gtk.gtk3.extraCss = lib.mkIf cfg.gtkCss "@import 'matugen.css';";
    gtk.gtk4.extraCss = lib.mkIf cfg.gtkCss "@import 'matugen.css';";
  };
}
