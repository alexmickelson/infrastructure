{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.shortcuts;
in
{
  config = {
    environment.systemPackages = lib.optionals (cfg.desktop == "gnome") [
      pkgs.gnomeExtensions.xremap
    ];

    services.xremap = {
      enable = true;
      serviceMode = "user";
      userName = cfg.user;
      watch = true;
      withGnome = cfg.desktop == "gnome";
      withKDE = cfg.desktop == "plasma";
      config.keymap = [
        {
          name = "macOS application shortcuts";
          remap = {
            "Alt-a" = "C-a";
            "Alt-c" = "C-insert";
            "Alt-f" = "C-f";
            "Alt-q" = "C-q";
            "Alt-s" = "C-s";
            "Alt-t" = "C-t";
            "Alt-v" = "S-insert";
            "Alt-w" = "C-w";
            "Alt-x" = "C-x";
            "Alt-z" = "C-z";
          };
        }
      ];
    };

    systemd.user.services.enable-xremap-extension = lib.mkIf (cfg.desktop == "gnome") {
      description = "Enable the xremap GNOME Shell extension";
      after = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      script = "${pkgs.gnome-shell}/bin/gnome-extensions enable xremap@k0kubun.com";
    };
  };
}
