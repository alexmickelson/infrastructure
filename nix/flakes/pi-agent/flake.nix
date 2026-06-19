{
  description = "Sandboxed launcher for the pi coding agent (bubblewrap-confined filesystem access)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      # Resolves to whatever `pi` means on the host running `nix run`.
      # Assumes pi is already installed via home-manager / nix profile,
      # matching `which pi` -> ~/.nix-profile/bin/pi.
      piSandboxed = pkgs.writeShellApplication {
        name = "pi-sandboxed";
        runtimeInputs = [ pkgs.bubblewrap ];
        text = ''
          set -euo pipefail

          WORKDIR="$(pwd)"
          HOME_DIR="''${HOME:?HOME must be set}"

          if ! command -v pi >/dev/null 2>&1; then
            echo "error: 'pi' not found on PATH. Is it installed via home-manager / nix profile?" >&2
            exit 1
          fi

          # Resolve the real binary so PATH lookups inside the sandbox
          # don't depend on profile symlink quirks.
          PI_BIN="$(command -v pi)"

          # Build the bind-mount list. --ro-bind/--bind entries are skipped
          # if the source path doesn't exist on the host, so this is safe
          # to run even if ~/.pi hasn't been created yet.
          BWRAP_ARGS=(
            --ro-bind /nix /nix
            --ro-bind /usr /usr
            --ro-bind /bin /bin
            --ro-bind /etc /etc
            --proc /proc
            --dev /dev
            --tmpfs /tmp
            --bind /tmp /tmp
            --bind "$WORKDIR" "$WORKDIR"
            --chdir "$WORKDIR"
            --unshare-all
            --share-net
            --die-with-parent
          )

          # ~/.nix-profile so the pi symlink and any sibling nix-profile
          # tooling resolve correctly inside the sandbox.
          if [ -e "$HOME_DIR/.nix-profile" ]; then
            BWRAP_ARGS+=(--ro-bind "$HOME_DIR/.nix-profile" "$HOME_DIR/.nix-profile")
          fi

          # ~/.config for API keys, MCP config, etc. (read-only)
          if [ -e "$HOME_DIR/.config" ]; then
            BWRAP_ARGS+=(--ro-bind "$HOME_DIR/.config" "$HOME_DIR/.config")
          fi

          # pi's own config / extensions directory (read-write so the agent
          # can create session state under ~/.pi/agent/sessions/).
          if [ -e "$HOME_DIR/.pi" ]; then
            BWRAP_ARGS+=(--bind "$HOME_DIR/.pi" "$HOME_DIR/.pi")
          fi

          exec bwrap "''${BWRAP_ARGS[@]}" -- "$PI_BIN" "$@"
        '';
      };
    in {
      packages.${system}.default = piSandboxed;

      apps.${system}.default = {
        type = "app";
        program = "${piSandboxed}/bin/pi-sandboxed";
      };
    };
}