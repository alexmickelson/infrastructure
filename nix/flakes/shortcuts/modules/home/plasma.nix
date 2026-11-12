{ config, lib, ... }:
{
  config = lib.mkIf (config.shortcuts.desktop == "plasma") {
    programs.plasma = {
      enable = true;

      shortcuts = {
        kwin = {
          "Overview" = "Alt+Space";
          "Window Operations Menu" = [ ];
          "Window Maximize" = "Meta+M";
          "Window Minimize" = "Alt+M";
        };
        "org.kde.spectacle.desktop" = {
          FullScreenScreenShot = "Shift+Alt+3";
          RectangularRegionScreenShot = "Shift+Alt+4";
        };
      };

      hotkeys.commands = {
        terminal = {
          name = "Terminal";
          comment = "Terminal";
          key = "Meta+T";
          command = config.shortcuts.terminal;
        };
        new-terminal = {
          name = "New terminal";
          comment = "New terminal";
          key = "Meta+Ctrl+N";
          command = config.shortcuts.terminal;
        };
      };
    };
  };
}
