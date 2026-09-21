{
  config,
  inputs,
  pkgs,
  ...
}:

{
  nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];

  nix.settings = {
    extra-substituters = [ "https://attic.xuyh0120.win/lantian" ];
    extra-trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
  };

  boot = {
    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-x86_64-v3;
    kernelParams = [ "mitigations=off" ];
    kernelModules = [
      "bfq"
      "hid_microsoft"
      "ntsync"
    ];
    zfs.package = config.boot.kernelPackages.zfs_cachyos;
    extraModprobeConfig = ''
      blacklist sp5100_tco
      options nvidia NVreg_InitializeSystemMemoryAllocations=0
    '';
    kernel.sysctl = {
      "vm.swappiness" = 150;
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_bytes" = 268435456;
      "vm.dirty_background_bytes" = 67108864;
      "vm.dirty_writeback_centisecs" = 1500;
      "vm.page-cluster" = 0;
      "kernel.nmi_watchdog" = 0;
      "kernel.split_lock_mitigate" = 0;
      "net.core.netdev_max_backlog" = 4096;
    };
  };

  programs = {
    steam = {
      enable = true;
      protontricks.enable = true;
    };
    gamemode = {
      enable = true;
      enableRenice = true;
      settings = {
        general = {
          desiredgov = "performance";
          ioprio = 0;
          renice = 15;
          softrealtime = "auto";
        };
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 0;
          nv_powermizer_mode = 1;
        };
      };
    };
    gamescope = {
      enable = true;
      capSysNice = true;
    };
  };

  services = {
    scx = {
      enable = true;
      scheduler = "scx_lavd";
    };
    pipewire.extraConfig.pipewire."92-low-latency"."context.properties" = {
      "default.clock.rate" = 48000;
      "default.clock.quantum" = 512;
      "default.clock.min-quantum" = 256;
      "default.clock.max-quantum" = 1024;
    };
    udev.extraRules = ''
      ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
      ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
      ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
      KERNEL=="ntsync", MODE="0660", TAG+="uaccess"
    '';
  };

  powerManagement.scsiLinkPolicy = "max_performance";

  zramSwap = {
    enable = true;
    algorithm = "lz4";
    memoryPercent = 50;
    priority = 100;
  };

  systemd.tmpfiles.rules = [
    "w! /sys/kernel/mm/transparent_hugepage/defrag - - - - defer+madvise"
    "w! /sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_none - - - - 409"
  ];

  environment = {
    sessionVariables = {
      PROTON_ENABLE_NVAPI = "1";
      PROTON_USE_NTSYNC = "1";
    };
    systemPackages = with pkgs; [
      mangohud
      protonup-ng
      umu-launcher
    ];
  };
}
