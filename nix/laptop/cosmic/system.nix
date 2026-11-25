{
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  services.displayManager.defaultSession = "cosmic";

  security.pam.services.cosmic-greeter.fprintAuth = true;

  shortcuts.desktop = "cosmic";
}
