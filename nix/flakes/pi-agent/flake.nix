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
          chromium
          podman
          fuse-overlayfs
          slirp4netns
          util-linux   # needed for `mount --make-rshared` inside the sandbox
        ];
        text = ''
          set -euo pipefail
          WORKDIR="$(pwd)"
          HOME_DIR="''${HOME:?HOME must be set}"

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

          containers_args=()
          if [ -d "$HOME_DIR/.local/share/containers" ]; then
            containers_args+=(--bind "$HOME_DIR/.local/share/containers" "$HOME_DIR/.local/share/containers")
          fi
          if [ -d "$HOME_DIR/.config/containers" ]; then
            containers_args+=(--bind "$HOME_DIR/.config/containers" "$HOME_DIR/.config/containers")
          fi

          etc_containers_args=()
          if [ -d /etc/containers ]; then
            etc_containers_args+=(--ro-bind /etc/containers /etc/containers)
          fi

          BWRAP_ARGS=(
            "''${path_args[@]}"
            --ro-bind "${pkgs.bash}/bin/bash" "/bin/bash"
            --ro-bind "${pkgs.bash}/bin/bash" "/bin/sh"
            --ro-bind /nix /nix
            --ro-bind /etc/ssl /etc/ssl
            --ro-bind /etc/resolv.conf /etc/resolv.conf
            --ro-bind /etc/hosts /etc/hosts
            --ro-bind /etc/subuid /etc/subuid
            --ro-bind /etc/subgid /etc/subgid
            --ro-bind /etc/passwd /etc/passwd
            --ro-bind /etc/group /etc/group
            --ro-bind /etc/nsswitch.conf /etc/nsswitch.conf
            "''${etc_containers_args[@]}"
            --ro-bind /run/ /run/
            --tmpfs "/run/user/$UID"
            --ro-bind /sys/fs/cgroup /sys/fs/cgroup
            --ro-bind /usr /usr
            --ro-bind /lib /lib
            --ro-bind /lib64 /lib64
            --proc /proc
            --dev /dev
            --dev-bind /dev/fuse /dev/fuse
            --dev-bind /dev/net/tun /dev/net/tun
            --tmpfs /tmp
            --bind "$WORKDIR" "$WORKDIR"
            --chdir "$WORKDIR"
            --unshare-all
            --share-net
            --die-with-parent
            --ro-bind "${pkgs.pi-coding-agent}" "${pkgs.pi-coding-agent}"
            --ro-bind "${pkgs.chromium}" "${pkgs.chromium}"
            "''${home_args[@]}"
            "''${pi_args[@]}"
            "''${containers_args[@]}"
          )
          echo "running with bubblewrap arguments: ''${BWRAP_ARGS[*]}"
          exec "${pkgs.bubblewrap}/bin/bwrap" "''${BWRAP_ARGS[@]}" -- \
            "${pkgs.bash}/bin/bash" -c '
              mount --make-rshared / 2>/dev/null || true
              exec "'"${pkgs.pi-coding-agent}"'/bin/pi" "$@"
            ' _ "$@"
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