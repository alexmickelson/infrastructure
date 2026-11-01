{ pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  systemd.user.services.hyprpolkitagent = {
    description = "Hyprland PolicyKit authentication agent";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.hyprpolkitagent}/bin/hyprpolkitagent";
      Restart = "on-failure";
    };
  };

  environment.systemPackages = with pkgs; [
    kitty
    kdePackages.dolphin
    kdePackages.breeze-icons
    hyprpaper
    hypridle
    hyprlock
    hyprpicker
    hyprmon
    waybar
    wofi
    mako
    libnotify
    cliphist
    wl-clip-persist
    grim
    slurp
    grimblast
    swayosd
    wl-clipboard
    playerctl
    brightnessctl
    pavucontrol
    networkmanagerapplet
    blueman
  ];
}
