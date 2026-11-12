{ config, lib, ... }:
{
  config = lib.mkIf (config.shortcuts.desktop == "gnome") {
    dconf.enable = true;

    dconf.settings = {
      "org/gnome/shell" = {
        disable-user-extensions = false;
      };
      "org/gnome/desktop/wm/preferences" = {
        mouse-button-modifier = "<Alt>";
        resize-with-right-button = true;
      };
      "org/gnome/desktop/wm/keybindings" = {
        minimize = [ "<Alt>m" ];
        toggle-maximized = [ "<Super>m" ];
        switch-applications = [ "<Alt>Tab" ];
        switch-applications-backward = [ "<Shift><Alt>Tab" ];
        switch-group = [ "<Alt>Above_Tab" ];
        switch-group-backward = [ "<Shift><Alt>Above_Tab" ];
      };
      "org/gnome/shell/keybindings" = {
        toggle-overview = [ "<Alt>space" ];
        screenshot = [ "<Shift><Alt>3" ];
        show-screenshot-ui = [ "<Shift><Alt>4" ];
      };
      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        ];
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        name = "Terminal";
        command = config.shortcuts.terminal;
        binding = "<Super>t";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        name = "New terminal";
        command = config.shortcuts.terminal;
        binding = "<Control><Super>n";
      };
    };
  };
}
