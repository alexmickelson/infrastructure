## Rebuild with: sudo nixos-rebuild switch --flake ~/projects/infrastructure/nix/ai-vm#ai-vm
{
  description = "Alex's AI VM NixOS and Home Manager configurations";

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
      aiVmPkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations.ai-vm = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          home-manager.nixosModules.home-manager
          ./ai-vm-system.nix
        ];
      };

      homeConfigurations."alex@ai-vm" = home-manager.lib.homeManagerConfiguration {
        pkgs = aiVmPkgs;
        extraSpecialArgs = { inherit inputs; };
        modules = [
          ./ai-vm.home.nix
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
