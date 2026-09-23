{
  description = "tv-computer NixOS configuration";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs =
    { nixpkgs, ... }:
    {
      nixosConfigurations.tv-computer = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./configuration.nix ];
      };
    };
}
