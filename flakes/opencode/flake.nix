{
  description = "OpenCode MCP dev shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            bash
            python313Packages.pyppeteer
            glib
            glib.out
            chromium
            uv
            nodejs_22
            opencode
          ];
          shellHook = ''
            export PUPPETEER_EXECUTABLE_PATH=${pkgs.chromium}/bin/chromium
          '';
        };
        packages.run = pkgs.writeShellScriptBin "run_flake" ''
            mkdir -p ~/.config/opencode
            cp ${self.packages.${system}.config_json}/config.json ~/.config/opencode/opencode.json
          ${pkgs.opencode}/bin/opencode
        '';
        packages.config_json = pkgs.writeTextFile {
          name = "config.json";
          text = ''
            {
              "$schema": "https://opencode.ai/config.json",
              "theme": "github",
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
