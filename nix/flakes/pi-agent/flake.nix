{
  description = "Sandboxed launcher for the pi coding agent with Podman remote access";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      piSandboxed = pkgs.writeShellApplication {
        name = "pi-sandboxed";

        runtimeInputs = with pkgs; [
          bubblewrap
          podman
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
          chromium
        ];

        text = ''
          set -euo pipefail

          WORKDIR="$(pwd)"
          HOME_DIR="$HOME"

          RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
          PODMAN_DIR="$RUNTIME_DIR/podman"
          PODMAN_SOCK="$PODMAN_DIR/podman.sock"

          path_args=()
          while IFS= read -r p; do
            [ -d "$p" ] || continue
            path_args+=(--ro-bind "$p" "$p")
          done < <(
            echo "$PATH" | tr ':' '\n' | awk '!seen[$0]++'
          )

          optional_args=()

          [ -d "$HOME_DIR/.nix-profile" ] &&
            optional_args+=(--ro-bind "$HOME_DIR/.nix-profile" "$HOME_DIR/.nix-profile")

          [ -d "$HOME_DIR/.pi" ] &&
            optional_args+=(--bind "$HOME_DIR/.pi" "$HOME_DIR/.pi")

          [ -d "$HOME_DIR/.config/containers" ] &&
            optional_args+=(--ro-bind "$HOME_DIR/.config/containers" "$HOME_DIR/.config/containers")

          if [ -S "$PODMAN_SOCK" ]; then
            optional_args+=(--bind "$PODMAN_DIR" "$PODMAN_DIR")
          fi

          exec ${pkgs.bubblewrap}/bin/bwrap \
            "''${path_args[@]}" \
            "''${optional_args[@]}" \
            --ro-bind /nix /nix \
            --ro-bind /usr /usr \
            --ro-bind /bin /bin \
            --ro-bind /lib /lib \
            --ro-bind /lib64 /lib64 \
            --ro-bind /etc /etc \
            --ro-bind /sys /sys \
            --bind /run /run \
            --proc /proc \
            --dev /dev \
            --tmpfs /tmp \
            --bind "$WORKDIR" "$WORKDIR" \
            --chdir "$WORKDIR" \
            --share-net \
            --die-with-parent \
            --setenv HOME "$HOME_DIR" \
            --setenv PATH "$PATH" \
            --setenv XDG_RUNTIME_DIR "$RUNTIME_DIR" \
            --setenv CONTAINER_HOST "unix://$PODMAN_SOCK" \
            --ro-bind ${pkgs.pi-coding-agent} ${pkgs.pi-coding-agent} \
            --ro-bind ${pkgs.chromium} ${pkgs.chromium} \
            -- \
            ${pkgs.pi-coding-agent}/bin/pi "$@"
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