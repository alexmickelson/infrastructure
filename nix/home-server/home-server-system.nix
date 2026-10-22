{
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ../modules/k3s.nix
    ../modules/pci-passthrough.nix
    ../modules/forgejo-runner.nix
  ];
  services.k3s.nodeIp = "100.110.207.108";

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
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
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

  users.users.alex = {
    isNormalUser = true;
    description = "alex";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "users"
      "libvirtd"
      "cdrom"
    ];
    shell = pkgs.fish;
  };
  home-manager.users.alex = { ... }: {
    home.stateVersion = "24.05";
    imports = [ ./home-server.home.nix ];
  };
  home-manager.extraSpecialArgs = { inherit inputs; };
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
    bash
    vim
    wget
    curl
    docker
    fish
    git
    zfs
    gcc-unwrapped
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
  services.tailscale.enable = true;
  services.tailscale.extraSetFlags = [
    "--stateful-filtering=false"
  ];
  services.envfs.enable = true;

  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  services.printing = {
    enable = true;
    drivers = [
      pkgs.brgenml1lpr
      pkgs.brgenml1cupswrapper
      pkgs.brlaser
    ];
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

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };
  networking.interfaces.br0.useDHCP = true;
  networking.bridges = {
    "br0" = {
      interfaces = [ "enp4s0" ];
    };
  };

  environment.etc = {
    "qemu/edk2-x86_64-secure-code.fd".source = lib.mkForce "${pkgs.OVMFFull.fd}/FV/OVMF_CODE.ms.fd";
    "qemu/edk2-x86_64-secure-vars.fd".source = lib.mkForce "${pkgs.OVMFFull.fd}/FV/OVMF_VARS.ms.fd";
    "qemu/OVMF_VARS.fd".source = lib.mkForce "${pkgs.OVMFFull.fd}/FV/OVMF_VARS.fd";
  };
  systemd.tmpfiles.rules = [
    "d /var/lib/libvirt/qemu/nvram 0755 root root -"
  ];

  powerManagement.powertop.enable = true;
  powerManagement.enable = true;
  powerManagement.cpuFreqGovernor = "powersave";

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  networking.hostId = "eafe9551";
  boot.zfs.extraPools = [
    "data-ssd"
    "backup"
    "vms-2"
    "vms-3"
  ];
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

  networking.firewall.enable = false;

  system.stateVersion = "24.05";
}
