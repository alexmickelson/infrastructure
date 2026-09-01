{
  description = "Sandboxed launcher for the pi coding agent";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;

      shellOptions = {
        additionalReadOnlyPaths = {
          type = "list of paths or absolute path strings";
          default = [ ];
          description = ''
            Additional host files or directories that Pi may read but not
            modify. Each path must be absolute and exist when Pi starts.
          '';
        };

        additionalReadWritePaths = {
          type = "list of paths or absolute path strings";
          default = [ ];
          description = ''
            Additional host files or directories that Pi may read and modify.
            Each path must be absolute and exist when Pi starts.
          '';
        };

        additionalPkgs = {
          type = "list of Nix packages";
          default = [ ];
          description = ''
            Additional Nix packages to add to Pi's PATH inside the sandbox.
          '';
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
        in
        pkgs.lib.makeOverridable (
          {
            additionalReadOnlyPaths ? [ ],
            additionalReadWritePaths ? [ ],
            additionalPkgs ? [ ],
            piAgentBinary ? null,
          }:
          let
            escapedReadOnlyPaths = pkgs.lib.escapeShellArgs (map toString additionalReadOnlyPaths);
            escapedReadWritePaths = pkgs.lib.escapeShellArgs (map toString additionalReadWritePaths);
            resolvedPiAgentBinary =
              if piAgentBinary == null then pkgs.lib.getExe pkgs.pi-coding-agent else toString piAgentBinary;
            escapedPiAgentBinary = pkgs.lib.escapeShellArg resolvedPiAgentBinary;

            commonRuntimeInputs =
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
              ])
              ++ additionalPkgs;

            linuxLauncher = pkgs.writeShellApplication {
              name = "pi-sandboxed";
              passthru = { inherit shellOptions; };

              runtimeInputs =
                commonRuntimeInputs
                ++ (with pkgs; [
                  bubblewrap
                  podman
                  chromium
                ]);

              text = ''
                set -euo pipefail

                WORKDIR="$(pwd)"
                HOME_DIR="$HOME"
                pi_binary=${escapedPiAgentBinary}

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
                additional_path_args=()

                additional_read_only_paths=( ${escapedReadOnlyPaths} )
                additional_read_write_paths=( ${escapedReadWritePaths} )

                for additional_path in "''${additional_read_only_paths[@]}"; do
                  if [[ "$additional_path" != /* ]] || [ ! -e "$additional_path" ]; then
                    echo "pi-sandboxed: additional read-only path must be absolute and exist: $additional_path" >&2
                    exit 1
                  fi
                  additional_path_args+=(--ro-bind "$additional_path" "$additional_path")
                done

                for additional_path in "''${additional_read_write_paths[@]}"; do
                  if [[ "$additional_path" != /* ]] || [ ! -e "$additional_path" ]; then
                    echo "pi-sandboxed: additional read-write path must be absolute and exist: $additional_path" >&2
                    exit 1
                  fi
                  additional_path_args+=(--bind "$additional_path" "$additional_path")
                done

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
                  "''${additional_path_args[@]}" \
                  --chdir "$WORKDIR" \
                  --share-net \
                  --die-with-parent \
                  --setenv HOME "$HOME_DIR" \
                  --setenv PATH "$PATH" \
                  --setenv XDG_RUNTIME_DIR "$RUNTIME_DIR" \
                  --setenv CONTAINER_HOST "unix://$PODMAN_SOCK" \
                  --ro-bind "$pi_binary" "$pi_binary" \
                  --ro-bind ${pkgs.chromium} ${pkgs.chromium} \
                  -- \
                  "$pi_binary" "$@"
              '';
            };

            darwinLauncher = pkgs.writeShellApplication {
              name = "pi-sandboxed";
              passthru = { inherit shellOptions; };

              runtimeInputs = commonRuntimeInputs ++ [ pkgs.tmux ];

              text = ''
                set -euo pipefail

                pi_binary=${escapedPiAgentBinary}

                project_dir="$(pwd -P)"
                home_dir="$(cd "$HOME" && pwd -P)"
                temp_dir="$(cd "''${TMPDIR:-/tmp}" && pwd -P)"
                pi_state_dir="$home_dir/.pi"

                cd "$project_dir"
                export PWD="$project_dir"

                export NPM_CONFIG_PREFIX="$pi_state_dir/npm"
                export npm_config_cache="$pi_state_dir/npm-cache"
                mkdir -p "$NPM_CONFIG_PREFIX" "$npm_config_cache"

                nix_cache_dir="$home_dir/.cache/nix"
                nix_state_dir="$home_dir/.local/state/nix"
                nix_config_dir="$home_dir/.config/nix"
                mkdir -p "$nix_cache_dir" "$nix_state_dir"

                nix_profile_link="$home_dir/.nix-profile"
                nix_profiles_dir="$home_dir/.local/state/nix/profiles"

                tmux_conf="$home_dir/.tmux.conf"
                tmux_config_dir="$home_dir/.config/tmux"

                additional_read_only_paths=( ${escapedReadOnlyPaths} )
                additional_read_write_paths=( ${escapedReadWritePaths} )

                read_only_paths=(
                  "$pi_binary"
                  "$nix_profile_link"
                  "$nix_profiles_dir"
                  "$nix_config_dir"
                  "$tmux_conf"
                  "$tmux_config_dir"
                  "''${additional_read_only_paths[@]}"
                )

                read_write_paths=(
                  "$project_dir"
                  "$pi_state_dir"
                  "$temp_dir"
                  "/nix"
                  "$nix_cache_dir"
                  "$nix_state_dir"
                  "''${additional_read_write_paths[@]}"
                )

                profile="$(mktemp)"
                trap 'rm -f "$profile"' EXIT
                cat > "$profile" <<'EOF'
                (version 1)
                (allow default)

                (deny file-write*)

                (allow file-write*
                  (literal "/dev/null")
                  (literal "/dev/zero")
                  (literal "/dev/tty")
                  (literal "/dev/ptmx")
                  (regex #"^/dev/ttys[0-9]+$"))

                (deny file-read* (subpath (param "home_dir")))

                (deny mach-lookup (global-name "com.apple.coreservices.appleevents"))
                EOF

                sandbox_path_args=()
                sandbox_path_index=0
                metadata_path_index=0

                validate_additional_path() {
                  local access="$1"
                  local path="$2"

                  if [[ "$path" != /* ]] || [ ! -e "$path" ]; then
                    echo "pi-sandboxed: additional $access path must be absolute and exist: $path" >&2
                    exit 1
                  fi
                }

                compose_sandbox_config() {
                  local access="$1"
                  local path="$2"
                  local path_filter
                  local path_param="sandbox_path_$sandbox_path_index"
                  local metadata_ancestor="$path"
                  local metadata_param

                  if [ -d "$path" ]; then
                    path_filter="subpath"
                  else
                    path_filter="literal"
                  fi

                  case "$access" in
                    read-only)
                      printf '(allow file-read* (%s (param "%s")))\n(deny file-write* (%s (param "%s")))\n' \
                        "$path_filter" "$path_param" "$path_filter" "$path_param" >> "$profile"
                      ;;
                    read-write)
                      printf '(allow file-read* file-write* (%s (param "%s")))\n' \
                        "$path_filter" "$path_param" >> "$profile"
                      ;;
                    *)
                      echo "pi-sandboxed: invalid sandbox access mode: $access" >&2
                      exit 1
                      ;;
                  esac

                  sandbox_path_args+=(-D "$path_param=$path")
                  sandbox_path_index=$((sandbox_path_index + 1))

                  while [ "$metadata_ancestor" != "/" ]; do
                    metadata_ancestor="$(dirname "$metadata_ancestor")"
                    metadata_param="sandbox_path_ancestor_$metadata_path_index"
                    printf '(allow file-read-metadata (literal (param "%s")))\n' \
                      "$metadata_param" >> "$profile"
                    sandbox_path_args+=(-D "$metadata_param=$metadata_ancestor")
                    metadata_path_index=$((metadata_path_index + 1))
                  done
                }

                for additional_path in "''${additional_read_only_paths[@]}"; do
                  validate_additional_path "read-only" "$additional_path"
                done

                for additional_path in "''${additional_read_write_paths[@]}"; do
                  validate_additional_path "read-write" "$additional_path"
                done

                for path in "''${read_write_paths[@]}"; do
                  compose_sandbox_config "read-write" "$path"
                done

                for path in "''${read_only_paths[@]}"; do
                  compose_sandbox_config "read-only" "$path"
                done

                echo "pi-sandboxed: Darwin sandbox profile:" >&2
                cat "$profile" >&2

                exec /usr/bin/sandbox-exec -f "$profile" \
                  -D "home_dir=$home_dir" \
                  "''${sandbox_path_args[@]}" \
                  "$pi_binary" "$@"
              '';
            };
          in
          if pkgs.stdenv.hostPlatform.isDarwin then darwinLauncher else linuxLauncher
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
          program = "${self.packages.${system}.default}/bin/pi-sandboxed";
        };
      });
    };
}
