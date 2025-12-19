
{ config, pkgs, lib, ... }:

{
  imports =
    [
      <home-manager/nixos>
      ./modules/k3s.nix
      ./modules/pci-passthrough.nix
    ];
  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "65000";
    }
    {
      domain = "*";
      type = "hard";
      item = "nofile";
      value = "65000";
    }
  ];
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  networking.networkmanager.enable = true;
  
  networking.nat.enable = true;
  
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 1;
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

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  users.users.github = {
    isNormalUser = true;
    description = "github";
    extraGroups = [ "docker" ];
    shell = pkgs.fish;
  };
  users.users.alex = {
    isNormalUser = true;
    description = "alex";
    extraGroups = [ "networkmanager" "wheel" "docker" "users" "libvirtd" "cdrom" ];
    shell = pkgs.fish;
  };
  home-manager.users.alex = { ...}: {
    home.stateVersion = "24.05";
    imports = [
      ./home-manager/alex.home.nix
      ./home-manager/server.home.nix
    ];
  };
  home-manager.useGlobalPkgs = true;

  services.fwupd.enable = true;
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
    github-runner
    sanoid
    virtiofsd
    qemu
    OVMF
    tmux
    (pkgs.writeShellScriptBin "qemu-system-x86_64-uefi" ''
      qemu-system-x86_64 \
        -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
        "$@"
    '')
  ];

  services.openssh.enable = true;
  programs.fish.enable = true;
  virtualisation.docker.enable = true;
  #virtualisation.docker.extraOptions = "--dns 1.1.1.1 --dns 8.8.8.8 --dns 100.100.100.100";
  services.tailscale.enable = true;
  services.tailscale.extraSetFlags = [
    "--stateful-filtering=false"
  ];
  services.envfs.enable = true;

  # printing
  services.printing = {
    enable = true;
    drivers = [ pkgs.brgenml1lpr pkgs.brgenml1cupswrapper pkgs.brlaser];
    listenAddresses = [ "*:631" ];

    extraConf = ''
      ServerAlias server.alexmickelson.guru
    '';
    allowFrom = [ "all" ];
    browsing = true;
    defaultShared = true;
    openFirewall = true;
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };

  systemd.services.printing-server = {
    description = "Web Printing Server Service";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.nix}/bin/nix run .#fastapi-server";
      Restart = "always";
      WorkingDirectory = "/home/alex/infrastructure/home-server/printing/server";
      User = "alex";
    };
  };

  # virtualization stuff
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmfPackages = [ pkgs.OVMFFull.fd ];
    };
  };
  networking.interfaces.enp5s0.useDHCP = true;
  networking.interfaces.br0.useDHCP = true;
  networking.bridges = {
    "br0" = {
      interfaces = [ "enp5s0" ];
    };
  };

  # not working yet, in theory simplifies xml for vm
  # environment.etc."qemu/edk2-x86_64-secure-code.fd".source = "${pkgs.OVMF.fd}/FV/OVMF_CODE.secboot.fd";
  # environment.etc."qemu/edk2-i386-vars.fd".source = "${pkgs.OVMF.fd}/FV/OVMF_VARS.fd";

  # environment.etc."qemu/edk2-x86_64-secure-code.fd".source = "${pkgs.OVMF.fd}/FV/OVMF_CODE.secboot.fd";
  # environment.etc."qemu/edk2-x86_64-secure-vars.fd".source = "${pkgs.OVMF.fd}/FV/OVMF_VARS.secboot.fd";

  environment.etc = {
    "qemu/edk2-x86_64-secure-code.fd".source =
      lib.mkForce "${pkgs.OVMF.fd}/FV/OVMF_CODE.ms.fd";
    "qemu/edk2-x86_64-secure-vars.fd".source =
      lib.mkForce "${pkgs.OVMF.fd}/FV/OVMF_VARS.ms.fd";
  };
  systemd.tmpfiles.rules = [
    "d /var/lib/libvirt/qemu/nvram 0755 root root -"
  ];

  powerManagement.powertop.enable = true;
  powerManagement.enable = true;
  powerManagement.cpuFreqGovernor = "powersave";

  # zfs stuff
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  networking.hostId = "eafe9551";
  boot.zfs.extraPools = [ "data-ssd" "backup" "vms" "vms-2" ];
  services.sanoid = {
    enable = true;
    templates.production = {
      hourly = 24;
      daily = 14;
      monthly = 5;
      autoprune = true;
      autosnap = true;
    };

    datasets."data-ssd/data" = {
      useTemplate = [ "production" ];
    };
    datasets."data-ssd/media" = {
      useTemplate = [ "production" ];
    };


    templates.backup = {
      hourly = 24;
      daily = 14;
      monthly = 5;
      autoprune = true;
      autosnap = false;
    };
    datasets."backup/data" = {
      useTemplate = [ "backup" ];
    };
    datasets."backup/media" = {
      useTemplate = [ "backup" ];
    };


    templates.vms = {
      hourly = 2;
      daily = 1;
      weekly = 2;
      autoprune = true;
      autosnap = true;
    };
    datasets."vms" = {
      useTemplate = [ "vms" ];
    };
    datasets."vms-2" = {
      useTemplate = [ "vms" ];
    };
  }; 

  services.github-runners = {
    infrastructure = {
      enable = true;
      name = "infrastructure-runner";
      user = "github";
      tokenFile = "/data/runner/github-infrastructure-token.txt";
      url = "https://github.com/alexmickelson/infrastructure";
      extraLabels = [ "home-server" ];
      #workDir = "/data/runner/infrastructure/";
      replace = true;
      serviceOverrides = { 
        ReadWritePaths = [ 
          "/data/cloudflare/" 
          "/data/runner/infrastructure" 
          "/data/runner" 
          "/home/github/infrastructure" 
        ];
        PrivateDevices = false;
        DeviceAllow = "/dev/zfs rw";
        ProtectProc = false;
        ProtectSystem = false;
        PrivateMounts = false;
        PrivateUsers = false;
        #DynamicUser = true;
        #NoNewPrivileges = false;
        ProtectHome = false;
        #RuntimeDirectoryPreserve = "yes";
        Restart = lib.mkForce  "always";
        #RuntimeMaxSec = "7d";
      };
      extraPackages = with pkgs; [
        docker
        git-secret
        zfs
        sanoid
        mbuffer
        lzop
      ];
    };
  };
  # services.cron = {
  #   enable = true;
  #   systemCronJobs = [
  #     "*/5 * * * *      root    date >> /tmp/cron.log"
  #   ];
  # };
  
  networking.firewall.enable = false;
  # networking.firewall.trustedInterfaces = [ "docker0" ]; 

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
