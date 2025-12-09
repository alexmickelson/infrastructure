{ config, pkgs, ... }:

{
  imports =
    [
      <home-manager/nixos>
      # /etc/nixos/cachix.nix
    ];
  
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  networking.hostName = "ai-office-server";
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;


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

  #https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  services.xserver.enable = true;
  services.displayManager = {
    gdm.enable = true;
    autoLogin = {
      enable = true;
      user = "alex";
    };
  };
  services.xserver.desktopManager.gnome.enable = true;
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  xdg.portal.config.common.default = [ "gnome" ];


  # services.xrdp.enable = true;

  # services.xrdp.defaultWindowManager = "${pkgs.gnome-session}/bin/gnome-session";
  # services.gnome.gnome-remote-desktop.enable = true;
  # services.xrdp.openFirewall = true;
  # services.displayManager.autoLogin.enable = false;
  # services.getty.autologinUser = null;

  # gnome rdp
  # services.gnome.gnome-remote-desktop.enable = true;
  # systemd.services.gnome-remote-desktop = {
  #   wantedBy = [ "graphical.target" ];
  # };


  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
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
    extraGroups = [ "networkmanager" "wheel" "docker" "video" "render" "input" ];
    shell = pkgs.fish;

    packages = with pkgs; [
      lazydocker
      btop
      nvtopPackages.amd
      uv
      git
      tmux
      vscode
      lmstudio
    ];
  };
  home-manager.users.alex = { pgks, ...}: {
    home.stateVersion = "25.11";
    imports = [
      ./home-manager/ai-vm.home.nix
    ];
  };

  programs.firefox.enable = true;
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.11"; # Did you read the comment?

  environment.systemPackages = with pkgs; [
    vim
    libva-utils 
    vulkan-tools 
    ffmpeg
    dbus
  ];
  programs.nix-ld.enable = true;

  programs.fish.enable = true;
  services.tailscale.enable = true;
  services.openssh.enable = true;
  virtualisation.docker.enable = true;
  hardware.amdgpu.opencl.enable = true;
  hardware.steam-hardware.enable = true;
  services.fwupd.enable = true;

  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  services.flatpak.enable = true;
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };


  hardware.graphics = {
    enable32Bit = true;
    enable = true;
  };
}
