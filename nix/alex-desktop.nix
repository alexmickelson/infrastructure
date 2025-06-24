{ config, pkgs, ... }: 
  
{
  imports =
    [
      <home-manager/nixos>
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "alex-desktop"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
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
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.printing.enable = true;
  hardware.pulseaudio.enable = false;
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
    extraGroups = [ "networkmanager" "wheel" "docker" "libvirtd" "adbusers" "kvm" ];
    shell = pkgs.fish;
    packages = with pkgs; [ ];
  };
  home-manager.users.alex = { pgks, ...}: {
    home.stateVersion = "24.11";
    imports = [
      ./home-manager/alex.home.nix
      ./home-manager/desktop.home.nix
    ];
  };
  home-manager.useGlobalPkgs = true;
  home-manager.backupFileExtension = "backup";

  programs.firefox.enable = true;
  services.fwupd.enable = true;
  hardware.enableAllFirmware = true;
  hardware.firmware = with pkgs; [ linux-firmware ];
  
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    docker
    fish
    git
    zfs
    gcc-unwrapped
    iputils
    tmux
    libguestfs-with-appliance
    iperf
    mangohud
    mlocate


    wineWowPackages.stable
    wine
    (wine.override { wineBuild = "wine64"; })
    wine64
    wineWowPackages.staging
    winetricks
    wineWowPackages.waylandFull
    # woeusb ntfs3g
  ];
  services.tailscale.enable = true;
  services.openssh.enable = true;
  virtualisation.docker.enable = true; 
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  programs.fish.enable = true;
  services.flatpak.enable = true;
  hardware.steam-hardware.enable = true;
  programs.adb.enable = true; # graphene

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };
  programs.gamemode.enable = true;
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };
  networking.firewall.enable = false;

  #services.sunshine = {
  #  enable = true;
  #  autoStart = false;
  #  capSysAdmin = true;
  #  package = (pkgs.sunshine.override { cudaSupport = true; });
  #  # openFirewall = true; 
  #};
  #services.sunshine = {
  #  enable = true;
  #  # Enable nvenc support
  #  package = with pkgs;
  #    (pkgs.sunshine.override {
  #      cudaSupport = true;
  #      cudaPackages = cudaPackages;
  #    })
  #    .overrideAttrs (old: {
  #      nativeBuildInputs =
  #        old.nativeBuildInputs
  #        ++ [
  #          cudaPackages.cuda_nvcc
  #          (lib.getDev cudaPackages.cuda_cudart)
  #        ];
  #      cmakeFlags =
  #        old.cmakeFlags
  #        ++ [
  #          "-DCMAKE_CUDA_COMPILER=${(lib.getExe cudaPackages.cuda_nvcc)}"
  #        ];
  #    });
  #  capSysAdmin = true;
  #};

  # hardware.nvidia = {
  #   modesetting.enable = true;
  #   open = false;
  #   nvidiaSettings = true;
  #   package = config.boot.kernelPackages.nvidiaPackages.production;
  #   powerManagement.enable = false;
  #   powerManagement.finegrained = false;
  # };
  # virtualisation.docker.enableNvidia = true;
  # hardware.nvidia-container-toolkit.enable = true;
  # services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics = {
    enable32Bit = true;
    enable = true;
  };

  fileSystems."/steam-data" =
  { 
    device = "/dev/disk/by-uuid/437358fd-b9e4-46e2-bd45-f6b368acaac1";
    fsType = "ext4";
  };
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  networking.hostId = "eafe9999";
  boot.zfs.extraPools = [ "data" "data2" ];
 

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
