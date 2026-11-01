{ pkgs, ... }:
let
  poke = pkgs.writeShellApplication {
    name = "hyprshell-poke";
    runtimeInputs = [ pkgs.hyprshell ];
    text = builtins.readFile ./poke.sh;
  };
in
{
  home.packages = [ pkgs.hyprshell ];

  xdg.configFile."hyprshell/config.ron".source = ./config.ron;

  systemd.user.services.hyprshell = {
    Unit = {
      Description = "Hyprland window switcher";
      PartOf = [ "graphical-session.target" ];
      After = [
        "graphical-session.target"
        "wallpaper-theme.service"
      ];
      Wants = [ "wallpaper-theme.service" ];
    };
    Service = {
      ExecStart = "${pkgs.hyprshell}/bin/hyprshell run";
      ExecStartPost = "-${poke}/bin/hyprshell-poke";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
