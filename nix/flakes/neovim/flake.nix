{
  description = "LazyVim-style neovim";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixvim, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      nvim = nixvim.legacyPackages.${system}.makeNixvimWithModule {
        module = {
          colorschemes.catppuccin = {
            enable = true;
            settings.flavour = "mocha";
          };

          plugins = {
            lualine.enable = true;
            telescope.enable = true;
            neo-tree.enable = true;
            which-key.enable = true;
            gitsigns.enable = true;

            treesitter = {
              enable = true;
              settings.ensure_installed = [ "elixir" "heex" "eex" "nix" "lua" ];
            };

            lsp = {
              enable = true;
              servers = {
                elixirls.enable = true;
                nixd.enable = true;
              };
            };

            blink-cmp = {
              enable = true;
              settings = {
                sources.default = [ "lsp" "path" "buffer" ];
                keymap.preset = "default";
              };
            };

            conform-nvim = {
              enable = true;
              settings.formatters_by_ft = {
                elixir = [ "mix" ];
                nix = [ "alejandra" ];
              };
            };
          };

          extraPackages = with pkgs; [
            nixd
            alejandra
            gcc
          ];

          opts = {
            relativenumber = true;
            scrolloff = 8;
            wrap = false;
          };
        };
      };
    in
    {
      packages.${system}.default = nvim;
      apps.${system}.default = {
        type = "app";
        program = "${nvim}/bin/nvim";
      };
    };
}