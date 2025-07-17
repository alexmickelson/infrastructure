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
            glib
            glib.out
            chromium
            uv
            nodejs_22
            opencode
          ];
        };
        packages.run = pkgs.writeShellScriptBin "run_flake" ''
          mkdir -p ~/.config/opencode
          cp ${self.packages.${system}.config_json} ~/.config/opencode/opencode.json
          ${pkgs.opencode}/bin/opencode
        '';
        packages.config_json = pkgs.writeTextFile {
          name = "config.json";
          text = ''
            {
              "$schema": "https://opencode.ai/config.json",
              "theme": "github",
              "mcp": {
                "memory": {
                  "type": "local",
                  "command": [ "npx", "-y", "@modelcontextprotocol/server-memory" ]
                },
                "playwright": {
                  "type": "local",
                  "command": [ 
                    "npx", 
                    "-y",
                    "@playwright/mcp@latest",
                    "--executable-path",
                    "${pkgs.chromium}/bin/chromium",
                    "--no-sandbox"
                  ]
                },
                "sequential_thinking": {
                  "type": "local",
                  "command": [ "npx", "-y", "@modelcontextprotocol/server-sequential-thinking"]
                }
              }
            }
          '';
        };
      });
}
