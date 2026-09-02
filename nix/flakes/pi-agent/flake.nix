{
  description = "Sandboxed launcher for the pi coding agent";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.agent-sandbox = {
    url = "../agent-sandbox";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      agent-sandbox,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;

      shellOptions = agent-sandbox.lib.shellOptions // {
        executableName = agent-sandbox.lib.shellOptions.executableName // {
          default = "pi-sandboxed";
        };

        piAgentBinary = {
          type = "null or an executable path string";
          default = null;
          description = ''
            Pi agent executable to launch. When null, the pi-coding-agent
            binary from this flake's nixpkgs input is used.
          '';
        };
      };

      mkPiSandboxed =
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          lib = pkgs.lib;
        in
        lib.makeOverridable (
          {
            additionalReadOnlyPaths ? [ ],
            additionalReadWritePaths ? [ ],
            additionalPkgs ? [ ],
            piAgentBinary ? null,
            executableName ? "pi-sandboxed",
          }:
          let
            piExecutable =
              if piAgentBinary == null then lib.getExe pkgs.pi-coding-agent else toString piAgentBinary;

            linuxConfig = {
              runtimeInputs =
                (with pkgs; [
                  bashInteractive
                  bash
                  coreutils
                  findutils
                  gnused
                  gawk
                  gnugrep
                  curl
                  wget
                  git
                  python3
                  nodejs
                  jq
                  file
                  less
                  man
                  podman
                  chromium
                ])
                ++ additionalPkgs;

              readOnlyPaths = [
                "~/.nix-profile"
                "~/.config/containers"
              ]
              ++ map toString additionalReadOnlyPaths;

              readWritePaths = [
                "."
                "~/.pi"
                "$TMPDIR"
                "/run"
              ]
              ++ map toString additionalReadWritePaths;

              prepareScript = ''
                mkdir -p "$HOME/.pi/npm" "$HOME/.pi/npm-cache"
              '';

              environmentScript = ''
                export NPM_CONFIG_PREFIX="$HOME/.pi/npm"
                export npm_config_cache="$HOME/.pi/npm-cache"
                export CONTAINER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
              '';
            };

            darwinConfig = {
              runtimeInputs =
                (with pkgs; [
                  bashInteractive
                  bash
                  coreutils
                  findutils
                  gnused
                  gawk
                  gnugrep
                  curl
                  wget
                  git
                  python3
                  nodejs
                  jq
                  file
                  less
                  man
                  tmux
                ])
                ++ additionalPkgs;

              readOnlyPaths = [
                "~/.nix-profile"
                "~/.local/state/nix/profiles"
                "~/.config/nix"
                "~/.tmux.conf"
                "~/.config/tmux"
              ]
              ++ map toString additionalReadOnlyPaths;

              readWritePaths = [
                "."
                "~/.pi"
                "$TMPDIR"
                "/nix"
                "~/.cache/nix"
                "~/.local/state/nix"
              ]
              ++ map toString additionalReadWritePaths;

              prepareScript = ''
                mkdir -p \
                  "$HOME/.pi/npm" \
                  "$HOME/.pi/npm-cache" \
                  "$HOME/.cache/nix" \
                  "$HOME/.local/state/nix"
              '';

              environmentScript = ''
                export NPM_CONFIG_PREFIX="$HOME/.pi/npm"
                export npm_config_cache="$HOME/.pi/npm-cache"
              '';
            };

            platformConfig = if pkgs.stdenv.hostPlatform.isDarwin then darwinConfig else linuxConfig;
          in
          agent-sandbox.lib.mkAgentSandbox {
            inherit pkgs executableName;
            inherit (platformConfig)
              runtimeInputs
              readOnlyPaths
              readWritePaths
              prepareScript
              environmentScript
              ;
            command = piExecutable;
            passthru = { inherit shellOptions; };
          }
        ) { };
    in
    {
      lib = { inherit shellOptions; };

      packages = forAllSystems (system: {
        default = mkPiSandboxed system;
      });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = nixpkgs.lib.getExe self.packages.${system}.default;
        };
      });
    };
}
