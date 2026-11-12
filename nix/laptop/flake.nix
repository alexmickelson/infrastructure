{
  description = "Laptop NixOS and Home Manager configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim = {
      url = "path:/home/alex/projects/neovim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    shortcuts = {
      url = "../flakes/shortcuts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pi-sandboxed = {
      url = "github:alexmickelson/infrastructure?dir=nix/flakes/pi-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    inputactions-kwin = {
      url = "git+https://github.com/InputActions/kwin?submodules=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    inputactions-ctl = {
      url = "git+https://github.com/InputActions/ctl?submodules=1";
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
      laptopPkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [ "electron-39.8.10" ];
        };
      };
    in
    {
      nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hardware-configuration.nix
          home-manager.nixosModules.home-manager
          inputs.shortcuts.nixosModules.default
          ./laptop-system.nix
        ];
      };

      homeConfigurations."alex@laptop" = home-manager.lib.homeManagerConfiguration {
        pkgs = laptopPkgs;
        extraSpecialArgs = { inherit inputs; };
        modules = [
          ./laptop.home.nix
          inputs.shortcuts.homeModules.default
          # inputs.plasma-manager.homeModules.plasma-manager
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
