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
    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  users.users.alex = {
    isNormalUser = true;
    description = "alex";
    extraGroups = [ "networkmanager" "wheel" "docker" "libvirtd" ];
    shell = pkgs.fish;
    packages = with pkgs; [
    ];
  };
  home-manager.users.alex = { pgks, ...}: {
    home.stateVersion = "24.11";
    home.packages = with pkgs; [
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
      vscode-fhs
      gnome-software
      gnome-tweaks
      (pkgs.nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
      nvtopPackages.nvidia
      htop
      dotnetCorePackages.dotnet_9.sdk
    ];
    fonts.fontconfig.enable = true;

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };
    gtk = {
      enable = true;
      theme = {
        name = "Adwaita-dark";
        package = pkgs.gnome-themes-extra;
      };
    };
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
  home-manager.backupFileExtension = "backup";

  programs.firefox.enable = true;
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
    tmux
    libguestfs-with-appliance
    iperf
  ];
  services.tailscale.enable = true;
  services.openssh.enable = true;
  virtualisation.docker.enable = true; 
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  programs.fish.enable = true;
  services.flatpak.enable = true;
  hardware.steam-hardware.enable = true;

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

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.production;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
  }; 
  services.xserver.deviceSection = ''
    Option         "TripleBuffer" "on"
    Option         "Coolbits" "28"
  '';

  services.xserver.screenSection = ''
    Option         "metamodes" "nvidia-auto-select +0+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}"
    Option         "AllowIndirectGLXProtocol" "off"
  '';
  # hardware.opengl = {
  #   enable = true;
  #   driSupport32Bit = true;
  # };
  hardware.graphics = {
    enable32Bit = true;
    enable = true;
  };
  virtualisation.docker.enableNvidia = true;
  hardware.nvidia-container-toolkit.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

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
