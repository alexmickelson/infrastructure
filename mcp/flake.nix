{
  description = "MCP server dev shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        configJsonText = ''
          {
            "mcpServers": {
              "memory": {
                "command": "npx",
                "args": ["-y", "@modelcontextprotocol/server-memory"]
              },
              "puppeteer": {
                "command": "npx",
                "args": ["-y", "@modelcontextprotocol/server-puppeteer"]
              },
              "playwright": {
                "command": "npx",
                "args": [
                  "-y",
                  "@playwright/mcp@latest",
                  "--executable-path",
                  "${pkgs.chromium}/bin/chromium"
                ]
              },
              "sequential_thinking": {
                "command": "npx",
                "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
              }
            }
          }
        '';

        config_json = pkgs.writeText "config.json" configJsonText;

      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.bash
            pkgs.python313Packages.pyppeteer
            pkgs.glib
            pkgs.glib.out
            pkgs.chromium
            pkgs.uv
            pkgs.nodejs_22
          ];
          shellHook = ''
            export PUPPETEER_EXECUTABLE_PATH=${pkgs.chromium}/bin/chromium
          '';
        };

        packages.run = pkgs.writeShellScriptBin "run_flake" ''
          uvx mcpo --port 8008 --config ${config_json}
        '';

        packages.config_json = config_json;
      });
}
