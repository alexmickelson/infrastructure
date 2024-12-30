# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "home-server"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  
  networking.nat.enable = true;
  
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 1;
  # Set your time zone.
  time.timeZone = "America/Denver";

  # Select internationalisation properties.
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

  # Configure keymap in X11
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
  home-manager.users.alex = { pgks, ...}: {
    home.stateVersion = "24.05";
    home.packages = with pkgs; [
      openldap
      k9s
      jwt-cli
      thefuck
      fish
      kubectl
      lazydocker
      btop
      nix-index
      usbutils
      makemkv
      mbuffer
      lzop
      lsof
      code-server
    ];
    programs.fish = {
      enable = true;
      shellAliases = {
        dang="fuck";
      };
      shellInit = ''
function commit
  git add --all
  git commit -m "$argv"
  git push
end

# have ctrl+backspace delete previous word
bind \e\[3\;5~ kill-word
# have ctrl+delete delete following word
bind \b  backward-kill-word

set -U fish_user_paths ~/.local/bin $fish_user_paths
#set -U fish_user_paths ~/.dotnet $fish_user_paths
#set -U fish_user_paths ~/.dotnet/tools $fish_user_paths

export VISUAL=vim
export EDITOR="$VISUAL"
export DOTNET_WATCH_RESTART_ON_RUDE_EDIT=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1
set -x LIBVIRT_DEFAULT_URI qemu:///system

thefuck --alias | source
     '';
    };
    home.file = {
    ".config/lazydocker/config.yml".text = ''
gui:
  returnImmediately: true
    '';
    ".config/k9s/config.yaml".text = ''
k9s:
  liveViewAutoRefresh: true
  screenDumpDir: /home/alexm/.local/state/k9s/screen-dumps
  refreshRate: 2
  maxConnRetry: 5
  readOnly: false
  noExitOnCtrlC: false
  ui:
    enableMouse: false
    headless: false
    logoless: false
    crumbsless: false
    reactive: false
    noIcons: false
    defaultsToFullScreen: false
  skipLatestRevCheck: false
  disablePodCounting: false
  shellPod:
    image: busybox:1.35.0
    namespace: default
    limits:
      cpu: 100m
      memory: 100Mi
  imageScans:
    enable: false
    exclusions:
      namespaces: []
      labels: {}
  logger:
    tail: 1000
    buffer: 5000
    sinceSeconds: -1
    textWrap: false
    showTime: false
  thresholds:
    cpu:
      critical: 90
      warn: 70
    memory:
      critical: 90
      warn: 70
  namespace:
    lockFavorites: false
      '';
    };
    home.sessionVariables = {
      EDITOR = "vim";
    };
  };
  home-manager.useGlobalPkgs = true;


  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
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
    tmux
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
  virtualisation.libvirtd.enable = true;

  # zfs stuff
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  networking.hostId = "eafe9551";
  boot.zfs.extraPools = [ "data-ssd" "backup" ];
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

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
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
