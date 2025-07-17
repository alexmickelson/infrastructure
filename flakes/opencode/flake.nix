{
  description = "OpenCode MCP dev shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
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
            export PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=${pkgs.chromium}/bin/chromium
            export PLAYWRIGHT_BROWSERS_PATH=0
          '';
        };
        packages.run = pkgs.writeShellScriptBin "run_flake" ''
          opencode --config ./config.json
        '';
        packages.config_json = pkgs.writeTextFile {
          name = "config.json";
          text = ''
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
        };
      });
}
