{
  nixosModule = { pkgs, ... }: {
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
            "Alt-c" = "C-S-c";
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
            "Alt-v" = "C-v";
            "Alt-w" = "C-w";
            "Alt-x" = "C-x";
            "Alt-z" = "C-z";
          };
        }
      ];
    };
  };
  homeManagerModule = {
    dconf.settings = {
      "org/gnome/desktop/wm/keybindings" = {
        minimize = [ "<Alt>m" ];
        switch-applications = [ "<Alt>Tab" ];
        switch-applications-backward = [ "<Shift><Alt>Tab" ];
        switch-group = [ "<Alt>Above_Tab" ];
        switch-group-backward = [ "<Shift><Alt>Above_Tab" ];
        toggle-maximized = [ "<Super>m" ];
      };
      "org/gnome/shell/keybindings" = {
        screenshot = [ "<Shift><Alt>3" ];
        show-screenshot-ui = [ "<Shift><Alt>4" ];
        toggle-overview = [ "<Alt>space" ];
      };
      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        ];
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        binding = "<Super>t";
        command = "ghostty";
        name = "terminal";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        binding = "<Control><Super>n";
        command = "ghostty";
        name = "new terminal";
      };
    };
  };
}
