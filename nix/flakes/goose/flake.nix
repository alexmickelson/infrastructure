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
            ollama = {
              npm = "@ai-sdk/openai-compatible";
              options = {
                baseURL = "http://ai-snow.reindeer-pinecone.ts.net:11434/v1";
              };
              models = {
                "llama3.1:70b" = { };
                "deepseek-r1:70b" = { };
                "mistral:latest" = { };
                "qwen3:32b" = { };
                "alibayram/Qwen3-30B-A3B-Instruct-2507" = { };
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
