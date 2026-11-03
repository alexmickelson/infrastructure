{ config, lib, pkgs, ... }:
let
  initializeHypr = pkgs.writeShellApplication {
    name = "initialize-hypr";
    runtimeInputs = [ pkgs.coreutils ];
    text = builtins.readFile ./initialize-hypr.sh;
  };

  reload = pkgs.writeShellApplication {
    name = "hyprland-reload";
    runtimeInputs = with pkgs; [
      hyprland
      hyprshell
    ];
    text = builtins.readFile ./reload.sh;
  };

  checkoutConfig = "${config.home.homeDirectory}/projects/infrastructure/nix/laptop/hyprland/config";
in
{
  imports = [
    ./hyprshell
    ./wallpaper-theme
    ./waybar
  ];

  home.packages = [
    initializeHypr
    reload
  ];

  home.activation.hyprlandConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${initializeHypr}/bin/initialize-hypr ${checkoutConfig}
  '';
}
