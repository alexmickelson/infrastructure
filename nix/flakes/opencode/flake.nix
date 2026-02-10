{
  description = "OpenCode MCP dev shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        opencodeConfig = {
          "$schema" = "https://opencode.ai/config.json";
          theme = "github";
          provider = {
            snow = {
              npm = "@ai-sdk/openai-compatible";
              options = {
                baseURL = "http://ai-snow.reindeer-pinecone.ts.net:9292/v1";
              };
              models = {
                "gpt-oss-120b" = { };
                "devstral-123b" = { };
              };
            };
            home = {
              npm = "@ai-sdk/openai-compatible";
              options = {
                baseURL = "http://openwebui.beefalo-newton.ts.net:9292/v1";
              };
              models = {
                "gpt-oss-20b" = { };
              };
            };
            office = {
              npm = "@ai-sdk/openai-compatible";
              options = {
                baseURL = "http://ai-office-server:8081/v1";
              };
              models = {
                "gpt-oss-20b" = { };
              };
            };
          };
          mcp = {
            playwright = {
              type = "local";
              command = [
                "npx"
                "-y"
                "@playwright/mcp@latest"
                "--executable-path"
                "${pkgs.chromium}/bin/chromium"
                "--no-sandbox"
              ];
            };
            # sequential_thinking = {
            #   type = "local";
            #   command = [
            #     "npx"
            #     "-y"
            #     "@modelcontextprotocol/server-sequential-thinking"
            #   ];
            # };
            # discord_bot = {
            #   type = "local";
            #   command = [
            #     "npx"
            #     "-y"
            #     "@pyroprompts/mcp-stdio-to-streamable-http-adapter"
            #   ];
            #   environment = {
            #     URI = "http://server.alexmickelson.guru:5678/mcp/";
            #     MCP_NAME = "discord_bot";
            #   };
            # };
          };
        };
        configJson = pkgs.writeTextFile {
          name = "config.json";
          text = builtins.toJSON opencodeConfig;
        };
      in {
        packages = rec {
          opencode = pkgs.writeShellScriptBin "opencode" ''
            mkdir -p ~/.config/opencode
            cp ${configJson} ~/.config/opencode/opencode.json
            ${pkgs.opencode}/bin/opencode
          '';
        };
      });
}
