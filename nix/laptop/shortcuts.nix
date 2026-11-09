{
  nixosModule =
    { ... }:
    {
      services.xremap = {
        enable = true;
        serviceMode = "user";
        userName = "alex";
        watch = true;
        withKDE = true;
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
