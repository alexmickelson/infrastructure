{ pkgs, ... }:
let
  reload = pkgs.writeShellApplication {
    name = "waybar-reload";
    runtimeInputs = with pkgs; [
      procps
      coreutils
    ];
    text = builtins.readFile ./reload.sh;
  };
in
{
  home.packages = [ reload ];

  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      targets = [ "graphical-session.target" ];
    };
    style = ./style.css;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 34;
      spacing = 4;
      "modules-left" = [
        "ext/workspaces"
      ];
      "modules-center" = [ "clock" ];
      "modules-right" = [
        "tray"
        "pulseaudio"
        "network"
        "bluetooth"
        "backlight"
        "battery"
        "cpu"
        "memory"
      ];

      # "ext/workspaces" = {
      #   format = "{name}";
      #   format-icons = [
      #     "1"
      #     "2"
      #     "3"
      #     "4"
      #     "5"
      #     "6"
      #     "7"
      #     "8"
      #     "9"
      #     "10"
      #   ];
        sort-by-id = true;
        all-outputs = true;
      };

      clock = {
        format = "{:%a %d %b  %I:%M %p}";
        tooltip-format = "<tt>{calendar}</tt>";
        calendar = {
          mode = "month";
          mode-mon-col = 3;
          weeks-pos = "right";
        };
      };

      tray = {
        icon-size = 16;
        spacing = 6;
      };

      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = "";
        format-icons.default = [
          ""
          ""
        ];
        on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
        tooltip-format = "{desc}";
      };

      network = {
        format-wifi = " {signalStrength}%";
        format-ethernet = "";
        format-disconnected = "";
        tooltip-format = "{ifname}  {essid}  {signalStrength}%";
        tooltip-format-disconnected = "offline";
        on-click = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
      };

      bluetooth = {
        format = "";
        format-connected = "";
        format-disabled = "";
        tooltip-format = "{controller_alias}";
        tooltip-format-connected = "{device_alias}\n{device_address}";
        on-click = "${pkgs.blueman}/bin/blueman-manager";
      };

      backlight = {
        format = "{percent}%";
        format-icons = [
          ""
          ""
        ];
      };

      battery = {
        format = "{capacity}% {icon}";
        format-icons = [
          "󰂎"
          "󰁺"
          "󰁻"
          "󰁼"
          "󰁽"
          "󰁾"
          "󰁿"
          "󰂀"
          "󰂁"
          "󰂂"
          "󰁹"
        ];
        states = {
          warning = 30;
          critical = 15;
        };
        tooltip-format = "{timeTo}";
      };

      cpu = {
        format = "󰻠 {usage}%";
        interval = 5;
        on-click = "${pkgs.btop}/bin/btop";
      };

      memory = {
        format = "󰍛 {percentage}%";
        interval = 5;
        tooltip-format = "{used:0.1f}G / {total:0.1f}G";
        on-click = "${pkgs.btop}/bin/btop";
      };
    };
  };
}
