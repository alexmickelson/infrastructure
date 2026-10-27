{
  description = "Laptop NixOS and Home Manager configurations";

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

    xremap-flake = {
      url = "github:xremap/nix-flake";
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
      shortcuts = import ./shortcuts.nix;
      laptopPkgs = import nixpkgs {
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

      nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hardware-configuration.nix
          home-manager.nixosModules.home-manager
          inputs.xremap-flake.nixosModules.default
          ./laptop-system.nix
          self.nixosModules.shortcuts
        ];
      };

      homeConfigurations."alex@laptop" = home-manager.lib.homeManagerConfiguration {
        pkgs = laptopPkgs;
        extraSpecialArgs = { inherit inputs; };
        modules = [
          ./laptop.home.nix
          self.homeManagerModules.shortcuts
          {
            home = {
              username = "alex";
              homeDirectory = "/home/alex";
              stateVersion = "26.05";
            };
          }
        ];
      };
    };
}
