{
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      gtk-theme = "Adwaita-dark";
      icon-theme = "Adwaita";
      cursor-theme = "Adwaita";
      font-name = "Adwaita Sans 11";
      document-font-name = "Adwaita Sans 11";
    };
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };
    "org/gnome/desktop/peripherals/touchpad" = {
      send-events = "enabled";
    };
    "org/gnome/shell" = {
      favorite-apps = [
        "com.mitchellh.ghostty.desktop"
        "org.gnome.Nautilus.desktop"
        "firefox.desktop"
      ];
    };
  };

  wallpaperTheme.gnome.enable = true;

  shortcuts.desktop = "gnome";
}
