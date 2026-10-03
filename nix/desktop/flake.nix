## Rebuild with: sudo nixos-rebuild switch --accept-flake-config --flake ~/projects/infrastructure/nix/desktop#alex-desktop
{
  description = "Alex's NixOS and Home Manager configurations";

  nixConfig = {
    extra-substituters = [ "https://attic.xuyh0120.win/lantian" ];
    extra-trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim = {
      url = "github:alexmickelson/neovim/";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pi-sandboxed = {
      url = "../flakes/pi-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    xremap-flake = {
      url = "github:xremap/nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
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
      shortcuts = import ./shortcuts.nix;
      desktopPkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [ "electron-39.8.10" ];
        };
      };
    in
    {
      nixosModules.shortcuts = shortcuts.nixosModule;
      homeManagerModules.shortcuts = shortcuts.homeManagerModule;

      nixosConfigurations.alex-desktop = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hardware-configuration.nix
          home-manager.nixosModules.home-manager
          inputs.xremap-flake.nixosModules.default
          ./desktop-system.nix
          self.nixosModules.shortcuts
        ];
      };

      homeConfigurations."alex@alex-desktop" = home-manager.lib.homeManagerConfiguration {
        pkgs = desktopPkgs;
        extraSpecialArgs = { inherit inputs; };
        modules = [
          ./desktop.home.nix
          self.homeManagerModules.shortcuts
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
