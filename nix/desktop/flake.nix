## Rebuild with: sudo nixos-rebuild switch --flake ~/projects/infrastructure/nix/desktop#alex-desktop
{
  description = "Alex's NixOS and Home Manager configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim = {
      url = "github:alexmickelson/neovim/e9ba3685edb183177dc5b067caac3a4372c6ac2d";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      system = "x86_64-linux";
      desktopPkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [ "electron-39.8.10" ];
        };
      };
    in
    {
      nixosConfigurations.alex-desktop = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hardware-configuration.nix
          home-manager.nixosModules.home-manager
          ./desktop-system.nix
        ];
      };

      homeConfigurations."alex@alex-desktop" = home-manager.lib.homeManagerConfiguration {
        pkgs = desktopPkgs;
        extraSpecialArgs = { inherit inputs; };
        modules = [
          ./desktop.home.nix
          {
            home = {
              username = "alex";
              homeDirectory = "/home/alex";
              stateVersion = "24.11";
            };
          }
        ];
      };
    };
}
