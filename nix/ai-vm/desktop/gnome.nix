{ pkgs, ... }:

{
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  services.displayManager = {
    gdm.enable = true;
    autoLogin = {
      enable = true;
      user = "alex";
    };
  };

  services.desktopManager.gnome.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    config.common.default = [ "gnome" ];
  };

  home-manager.users.alex =
    { lib, pkgs, ... }:
    {
      home.packages = with pkgs; [
        gnome-software
        gnome-tweaks
      ];

      dconf = {
        enable = true;
        settings = {
          "org/gnome/desktop/session".idle-delay = lib.hm.gvariant.mkUint32 0;
          "org/gnome/desktop/interface".color-scheme = "prefer-dark";
          "org/gnome/desktop/wm/keybindings".toggle-maximized = [ "<Super>m" ];
          "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
            binding = "<Super>t";
            command = "ghostty";
            name = "terminal";
          };
        };
      };
    };
}
