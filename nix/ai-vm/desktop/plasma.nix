{
  environment.sessionVariables.KWIN_DRM_DEVICES = "/dev/dri/nvidia-card:/dev/dri/qxl-card";

  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card[0-9]*", KERNELS=="0000:01:00.0", SYMLINK+="dri/nvidia-card"
    SUBSYSTEM=="drm", KERNEL=="card[0-9]*", KERNELS=="0000:00:01.0", SYMLINK+="dri/qxl-card"
  '';

  services.xserver.xkb.layout = "us";

  services.displayManager = {
    defaultSession = "plasma";
    autoLogin = {
      enable = true;
      user = "alex";
    };
    sddm = {
      enable = true;
      wayland.enable = true;
    };
  };

  services.desktopManager.plasma6.enable = true;
}
