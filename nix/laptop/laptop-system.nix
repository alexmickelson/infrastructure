{
  desktop,
  inputs,
  pkgs,
  ...
}:

{
  imports = [ ./desktop.nix ];

  nixpkgs.config = {
    allowUnfree = true;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "laptop";
  networking.networkmanager.enable = true;

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

  services.logiops = {
    enable = true;
    config.devices = [
      {
        name = "Wireless Mouse MX Master 3";
        buttons = [
          {
            cid = 195;
            action = {
              type = "Keypress";
              keys = [ "KEY_LEFTMETA" ];
            };
          }
        ];
      }
    ];
  };
  services.printing.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.fwupd.enable = true;

  services.fprintd.enable = true;
  security.pam.services.polkit-1.fprintAuth = true;
  security.pam.services.sudo.fprintAuth = false;
  services.gnome.gnome-keyring.enable = true;

  services.upower.enable = true;
  services.tailscale.enable = true;
  services.openssh.enable = true;
  services.flatpak.enable = true;

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
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.steam-hardware.enable = true;
  zramSwap.enable = true;

  users.groups.plugdev = { };
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
      "plugdev"
    ];
    shell = pkgs.fish;
  };

  home-manager = {
    extraSpecialArgs = { inherit desktop inputs; };
    useGlobalPkgs = true;
    backupFileExtension = "backup";
    users.alex = { ... }: {
      home.stateVersion = "26.05";
      imports = [
        ./laptop.home.nix
        (import ./shortcuts.nix).homeManagerModule
      ];
    };
  };

  programs.firefox.enable = true;
  programs.nix-ld.enable = true;
  programs.virt-manager.enable = true;
  programs.fish.enable = true;
  programs.steam.enable = true;
  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    gcc
    iputils
    tmux
    iperf
    mlocate
    (pkgs.writeTextDir "share/polkit-1/actions/com.bitwarden.Bitwarden.policy" ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE policyconfig PUBLIC
       "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
       "http://www.freedesktop.org/standards/PolicyKit/1.0/policyconfig.dtd">
      <policyconfig>
        <action id="com.bitwarden.Bitwarden.unlock">
          <description>Unlock Bitwarden</description>
          <message>Authenticate to unlock Bitwarden</message>
          <defaults>
            <allow_any>no</allow_any>
            <allow_inactive>no</allow_inactive>
            <allow_active>auth_self</allow_active>
          </defaults>
        </action>
      </policyconfig>
    '')
  ];

  system.stateVersion = "26.05";
}
