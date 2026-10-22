{
  description = "Home server NixOS and Home Manager configurations";

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
  };

  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      ...
    }:
    let
      system = "x86_64-linux";
      serverPkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations.home-server = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hardware-configuration.nix
          home-manager.nixosModules.home-manager
          ./home-server-system.nix
        ];
      };

      homeConfigurations."alex@home-server" = home-manager.lib.homeManagerConfiguration {
        pkgs = serverPkgs;
        extraSpecialArgs = { inherit inputs; };
        modules = [
          ./home-server.home.nix
          {
            home = {
              username = "alex";
              homeDirectory = "/home/alex";
              stateVersion = "24.05";
            };
          }
        ];
      };
    };
}
