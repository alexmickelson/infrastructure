{ inputs, pkgs, ... }:

{
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [ "electron-39.8.10" ];
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  boot.zfs.extraPools = [
    "data"
    "data2"
  ];

  networking.hostName = "alex-desktop";
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;
  networking.hostId = "eafe9999";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

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
  services.logiops = {
    enable = true;
    config = {
      devices = [
        {
          # The MX Master 3 thumb-rest / gesture button.
          name = "Wireless Mouse MX Master 3";
          buttons = [
            {
              cid = 195; # 0xc3
              action = {
                type = "Keypress";
                keys = [ "KEY_LEFTMETA" ];
              };
            }
          ];
        }
      ];
    };
  };
  services.printing.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber = {
      enable = true;
      extraConfig."disable-x11"."wireplumber.settings"."support.x11" = false;
    };
  };
  services.fwupd.enable = true;
  services.tailscale.enable = true;
  services.openssh.enable = true;
  services.flatpak.enable = true;

  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
  systemd.timers."nix-garbage-collect-weekly" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };
  systemd.services."nix-garbage-collect-weekly" = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/run/current-system/sw/bin/nix-collect-garbage --delete-older-than 7d";
    };
  };

  security.rtkit.enable = true;
  hardware.enableAllFirmware = true;
  hardware.firmware = with pkgs; [ linux-firmware ];
  hardware.steam-hardware.enable = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  users.users.alex = {
    isNormalUser = true;
    description = "alex";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "libvirtd"
      "adbusers"
      "kvm"
    ];
    shell = pkgs.fish;
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    useGlobalPkgs = true;
    backupFileExtension = "backup";
    users.alex = { ... }: {
      home.stateVersion = "24.11";
      imports = [ ./desktop.home.nix ];
    };
  };

  programs.firefox.enable = true;
  programs.nix-ld.enable = true;
  programs.virt-manager.enable = true;
  programs.fish.enable = true;

  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    docker
    fish
    git
    zfs
    gcc
    iputils
    tmux
    libguestfs-with-appliance
    iperf
    mlocate
  ];

  fileSystems."/steam-data" = {
    device = "/dev/disk/by-uuid/437358fd-b9e4-46e2-bd45-f6b368acaac1";
    fsType = "ext4";
  };

  system.stateVersion = "24.11";
}
