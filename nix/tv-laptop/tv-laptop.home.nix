{ pkgs, ... }:
{
  home.stateVersion = "26.05";
  home.packages = [
    pkgs.kdePackages.discover
    pkgs.kdePackages.kate
    pkgs.vim
  ];
}
