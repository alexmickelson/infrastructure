{
  description = "MCP server dev shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.bash
            pkgs.python313Packages.pyppeteer
            pkgs.python312
            pkgs.glib
            pkgs.glib.out
            pkgs.chromium
            pkgs.uvx
            pkgs.nodejs_22
          ];
          shellHook = ''
            export PUPPETEER_EXECUTABLE_PATH=${pkgs.chromium}/bin/chromium
          '';
        };
        packages.run = pkgs.writeShellScriptBin "run_flake" ''
          uvx mcpo --port 8008 --config ./config.json
        '';
      });
}
