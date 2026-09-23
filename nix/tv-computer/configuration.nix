{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../tv-computer.nix
  ];

  networking.hostName = "tv-computer";
}
