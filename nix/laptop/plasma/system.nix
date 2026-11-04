{
  config,
  pkgs,
  lib,
  utils,
  inputs,
  ...
}:
{
  services.desktopManager.plasma6.enable = true;

  services.displayManager.plasma-login-manager.enable = true;

  powerManagement.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  qt = {
    platformTheme = "kde";
    style = "breeze";
  };

  security.pam.services.plasmalogin.rules.auth = lib.mkForce (
    utils.pam.autoOrderRules [
      {
        name = "unix";
        control = "optional";
        modulePath = config.security.pam.pam_unixModulePath;
        settings = {
          nullok = true;
          likeauth = true;
        };
      }
      {
        name = "kwallet";
        control = "optional";
        modulePath = "${pkgs.kdePackages.kwallet-pam}/lib/security/pam_kwallet5.so";
      }
      {
        name = "gnome_keyring";
        control = "optional";
        modulePath = "${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so";
      }
      {
        name = "unix-final";
        control = "sufficient";
        modulePath = config.security.pam.pam_unixModulePath;
        settings = {
          nullok = true;
          likeauth = true;
          try_first_pass = true;
        };
      }
      {
        name = "fprintd";
        control = "sufficient";
        modulePath = "${config.services.fprintd.package}/lib/security/pam_fprintd.so";
      }
      {
        name = "deny";
        control = "required";
        modulePath = "${config.security.pam.package}/lib/security/pam_deny.so";
      }
    ]
  );

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };

  environment.systemPackages = with pkgs; [
    # InputActions: touchpad gestures are compiled into kwin (no kwinrc option),
    # so the 3-/4-finger swipe swap is done by this plugin instead of patching
    # kwin source (a source patch rebuilds kwin, ~30+ min, non-viable). It
    # intercepts swipes at kwin's input layer and blocks the built-in gestures
    # while its own are active. Gestures live in
    # ~/.config/inputactions/config.yaml (managed by home-manager); edit live
    # with `inputactions config reload`.
    inputs.inputactions-kwin.packages.${stdenv.hostPlatform.system}.default
    inputs.inputactions-ctl.packages.${stdenv.hostPlatform.system}.default

    kitty
    libnotify
    cliphist
    wl-clip-persist
    wl-clipboard
    grim
    slurp
    grimblast
    swayosd
    hyprpicker
    brightnessctl
    playerctl
    pavucontrol
    networkmanagerapplet
    blueman
  ];
}
