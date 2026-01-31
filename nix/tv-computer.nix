
{ config, pkgs, ... }:

{
  imports = [ ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxKernel.kernels.linux_6_6;
  # boot.extraModulePackages = with config.boot.kernelPackages; [ xpadneo ];
  # boot.kernelModules = [ "hid_xpadneo" ];
  # boot.kernelModules = [
  #   "hid_microsoft" # Xbox One Elite 2 controller driver preferred by Steam
  #   "uinput"
  # ];
  #boot.kernelPackages = pkgs.linuxPackages_6_6;
  boot.kernelParams = [
    "amdgpu.discovery=1"
  ];

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  networking.networkmanager.enable = true;

  time.timeZone = "America/Denver";
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  services.printing.enable = true;
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.alex = {
    isNormalUser = true;
    description = "alex";
    extraGroups = [ "networkmanager" "wheel" "docker" "input" ];
    packages = with pkgs; [
      firefox
      docker
      lazydocker
      k9s
    ];
    shell = pkgs.fish;
  };

  programs.firefox.enable = true;
  nixpkgs.config.allowUnfree = true;
  services.fwupd.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    gnome-tweaks
    docker
    btop
    vscode-fhs
    libvirt
    numix-cursor-theme
    ffmpeg
    libva-utils
    libcec
    flirc

  ];
  services.openssh.enable = true;
  services.tailscale.enable = true;
  hardware.flirc.enable = true;
  hardware.steam-hardware.enable = true;
  # hardware.xpadneo.enable = true;
  hardware.xone.enable = true;

  programs.fish.enable = true;
  virtualisation.docker.enable = true;
  services.flatpak.enable = true;
  # virtualisation.libvirtd.enable = true;
  # programs.virt-manager.enable = true;


  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  system.stateVersion = "25.11"; # Did you read the comment?

}
