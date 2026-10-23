{ pkgs, ... }:
{
  imports = [ ../home-manager/fish.home.nix ];

  home.stateVersion = "26.05";
  home.packages = [
    pkgs.git
    pkgs.kdePackages.discover
    pkgs.kdePackages.kate
    pkgs.vim
  ];
}
