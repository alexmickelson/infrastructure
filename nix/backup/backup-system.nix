{ pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  # boot.zfs.extraPools = [
  #   "pool-name"
  # ];

  networking.hostName = "backup";
  networking.hostId = "28661dba";
  networking.networkmanager.enable = true;

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  time.timeZone = "America/Denver";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.alex = {
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      vim
      git
      ripgrep
    ];
    shell = pkgs.fish;
  };

  programs.fish.enable = true;
  environment.systemPackages = [ pkgs.zfs ];
  services.openssh.enable = true;
  services.tailscale.enable = true;

  system.stateVersion = "26.05";
}
