{ pkgs, ... }:
{
  home.packages = [ pkgs.libinput-gestures ];

  xdg.configFile."libinput-gestures.conf".text = ''
    gesture swipe up 3 cosmic-workspaces
  '';

  systemd.user.services.libinput-gestures = {
    Unit = {
      Description = "Touchpad gestures";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.libinput-gestures}/bin/libinput-gestures";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
