{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./system.nix
  ];

  networking.hostName = "tv-computer";
}
