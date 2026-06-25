{
  description = "Sandboxed launcher for the pi coding agent (bubblewrap-confined filesystem access)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      piSandboxed = pkgs.writeShellApplication {
        name = "pi-sandboxed";
        runtimeInputs = with pkgs; [
          bubblewrap
          bashInteractive coreutils findutils gnused gawk gnugrep curl wget git
          python3 nodejs jq file less man
          bash
        ];
        text = ''
          set -euo pipefail

          WORKDIR="$(pwd)"
          HOME_DIR="''${HOME:?HOME must be set}"

          # Collect unique, existing directories from $PATH
          path_dirs=$(echo "$PATH" | tr ':' '\n' | sed 's|/$||' | awk '!seen[$0]++ && system("test -d " $0) == 0 {print}')

          path_args=()
          if [ -n "$path_dirs" ]; then
            while IFS= read -r path; do
              path_args+=(--ro-bind "$path" "$path")
            done <<< "$path_dirs"
          fi

          home_args=()
          if [ -e "$HOME_DIR/.nix-profile" ]; then
            home_args+=(--ro-bind "$HOME_DIR/.nix-profile" "$HOME_DIR/.nix-profile")
          fi

          pi_args=()
          if [ -e "$HOME_DIR/.pi" ]; then
            pi_args+=(--bind "$HOME_DIR/.pi" "$HOME_DIR/.pi")
          fi


          BWRAP_ARGS=(
            "''${path_args[@]}"
            --ro-bind "${pkgs.bash}/bin/bash" "/bin/bash"
            --ro-bind "${pkgs.bash}/bin/bash" "/bin/sh"
            --ro-bind /nix /nix
            --ro-bind /etc/ssl /etc/ssl
            --ro-bind /etc/resolv.conf /etc/resolv.conf
            --ro-bind /etc/hosts /etc/hosts
            --ro-bind /run/current-system /run/current-system
            --ro-bind /usr /usr
            --ro-bind /lib /lib
            --ro-bind /lib64 /lib64
            --proc /proc
            --dev /dev
            --tmpfs /tmp
            --bind "$WORKDIR" "$WORKDIR"
            --chdir "$WORKDIR"
            --unshare-all
            --share-net
            --die-with-parent
            --ro-bind "${pkgs.pi-coding-agent}" "${pkgs.pi-coding-agent}"
            "''${home_args[@]}"
            "''${pi_args[@]}"
          )

          echo "running with bubblewrap arguments: ''${BWRAP_ARGS[*]}"

          exec "${pkgs.bubblewrap}/bin/bwrap" "''${BWRAP_ARGS[@]}" -- "${pkgs.pi-coding-agent}/bin/pi" "$@"
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