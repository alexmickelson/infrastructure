{
  description = "keyboard shortucts and remappings";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.xremap-flake = {
    url = "github:xremap/nix-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.plasma-manager = {
    url = "github:nix-community/plasma-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      nixpkgs,
      xremap-flake,
      plasma-manager,
      ...
    }:
    let
      lib = nixpkgs.lib;

      desktop = {
        options.shortcuts.desktop = lib.mkOption {
          type = lib.types.enum [
            "gnome"
            "plasma"
          ];
          description = "Desktop environment whose shortcut settings are generated.";
        };
      };

      user = {
        options.shortcuts.user = lib.mkOption {
          type = lib.types.str;
          description = "User whose graphical session runs xremap.";
        };
      };

      terminal = {
        options.shortcuts.terminal = lib.mkOption {
          type = lib.types.str;
          default = "ghostty --gtk-single-instance=true";
          description = "Command launched by the terminal shortcuts.";
        };
      };
    in
    {
      nixosModules.default = {
        imports = [
          xremap-flake.nixosModules.default
          desktop
          user
          ./modules/nixos/xremap.nix
        ];
      };

      homeModules.default = {
        imports = [
          desktop
          terminal
          plasma-manager.homeModules.plasma-manager
          ./modules/home/gnome.nix
          ./modules/home/plasma.nix
        ];
      };
    };
}
