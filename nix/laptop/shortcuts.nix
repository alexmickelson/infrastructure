{
  nixosModule =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.gnomeExtensions.xremap ];

      systemd.user.services.enable-xremap-extension = {
        description = "Enable xremap GNOME extension";
        after = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        script = ''
          ${pkgs.gnome-shell}/bin/gnome-extensions enable xremap@k0kubun.com
        '';
      };

      services.xremap = {
        enable = true;
        serviceMode = "user";
        userName = "alex";
        watch = true;
        withGnome = true;
        config.keymap = [
          {
            name = "Ghostty clipboard";
            application.only = [ "/(?i)(com\\.mitchellh\\.ghostty|ghostty)/" ];
            remap = {
              "Alt-c" = "C-insert";
              "Alt-v" = "C-S-v";
            };
          }
          {
            name = "macOS application shortcuts";
            remap = {
              "Alt-a" = "C-a";
              "Alt-c" = "C-c";
              "Alt-f" = "C-f";
              "Alt-q" = "C-q";
              "Alt-s" = "C-s";
              "Alt-t" = "C-t";
              "Alt-v" = "C-v";
              "Alt-w" = "C-w";
              "Alt-x" = "C-x";
              "Alt-z" = "C-z";
            };
          }
        ];
      };
    };

  homeManagerModule =
    { ... }:
    {
      dconf.settings."org/gnome/shell".disable-user-extensions = false;

      # programs.plasma.shortcuts = {
      #   kwin = {
      #     "Window Close" = "Meta+C";
      #     "Edit Tiles" = "Meta+Shift+T";
      #     "Overview" = "Meta+Space";
      #     "Window Maximize" = "Meta+M";
      #   };
      #
      #   "services/com.mitchellh.ghostty.desktop" = {
      #     _launch = "Meta+T";
      #     "new-window" = "Meta+Ctrl+N";
      #   };
      #
      #   "services/org.kde.dolphin.desktop" = {
      #     _launch = "Meta+E";
      #   };
      # };
    };
}
