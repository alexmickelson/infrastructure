{
  description = "Reusable sandboxed launcher for coding agents";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      shellOptions = {
        additionalReadOnlyPaths = {
          type = "list of path strings";
          default = [ ];
          description = ''
            Additional files or directories that the agent may read but not
            modify. Paths may be absolute, relative to the working directory,
            relative to home with ~, or use $TMPDIR or $XDG_RUNTIME_DIR.
          '';
        };

        additionalReadWritePaths = {
          type = "list of path strings";
          default = [ ];
          description = ''
            Additional files or directories that the agent may read and
            modify. Paths may be absolute, relative to the working directory,
            relative to home with ~, or use $TMPDIR or $XDG_RUNTIME_DIR.
          '';
        };

        additionalPkgs = {
          type = "list of Nix packages";
          default = [ ];
          description = "Additional Nix packages to add to the agent's PATH.";
        };

        executableName = {
          type = "string";
          default = "agent-sandboxed";
          description = "Name of the executable produced by the sandbox package.";
        };
      };

      mkAgentSandbox =
        {
          pkgs,
          command,
          executableName ? "agent-sandboxed",
          runtimeInputs ? [ ],
          readOnlyPaths ? [ ],
          readWritePaths ? [ ],
          environment ? { },
          environmentScript ? "",
          prepareScript ? "",
          shareNetwork ? true,
          passthru ? { },
        }:
        let
          lib = pkgs.lib;
          commandString = toString command;
          escapedCommand = lib.escapeShellArg commandString;
          escapedExecutableName = lib.escapeShellArg executableName;
          escapedReadOnlyPaths = lib.escapeShellArgs (map toString readOnlyPaths);
          escapedReadWritePaths = lib.escapeShellArgs (map toString readWritePaths);
          invalidEnvironmentNames = lib.filterAttrs (
            name: _: builtins.match "[A-Za-z_][A-Za-z0-9_]*" name == null
          ) environment;
          environmentExports = lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
              name: value: "export ${name}=${lib.escapeShellArg (toString value)}"
            ) environment
          );
          linuxNetworkArgs = lib.optionalString (!shareNetwork) "--unshare-net";
          darwinNetworkRule = lib.optionalString (!shareNetwork) "(deny network*)";

          commonScript = ''
            workdir="$(pwd -P)"
            home_dir="$(cd "$HOME" && pwd -P)"
            temp_dir="$(cd "''${TMPDIR:-/tmp}" && pwd -P)"
            runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
            command_path=${escapedCommand}

            if [ ! -x "$command_path" ]; then
              printf '%s: command is not executable: %s\n' \
                ${escapedExecutableName} "$command_path" >&2
              exit 1
            fi

            export HOME="$home_dir"
            export TMPDIR="$temp_dir"
            export XDG_RUNTIME_DIR="$runtime_dir"
            ${environmentExports}
            ${environmentScript}
            ${prepareScript}

            # These values are path templates resolved by resolve_path below.
            # shellcheck disable=SC2016,SC2088
            configured_read_only_paths=( ${escapedReadOnlyPaths} )
            # shellcheck disable=SC2016,SC2088
            configured_read_write_paths=( ${escapedReadWritePaths} )
            resolved_read_only_paths=()
            resolved_read_write_paths=()

            resolve_path() {
              local configured_path="$1"

              case "$configured_path" in
                \~)
                  printf '%s\n' "$home_dir"
                  ;;
                \~/*)
                  printf '%s/%s\n' "$home_dir" "''${configured_path#\~/}"
                  ;;
                '.')
                  printf '%s\n' "$workdir"
                  ;;
                './'*)
                  printf '%s/%s\n' "$workdir" "''${configured_path#./}"
                  ;;
                \$TMPDIR)
                  printf '%s\n' "$temp_dir"
                  ;;
                \$TMPDIR/*)
                  printf '%s/%s\n' "$temp_dir" "''${configured_path#\$TMPDIR/}"
                  ;;
                \$XDG_RUNTIME_DIR)
                  printf '%s\n' "$runtime_dir"
                  ;;
                \$XDG_RUNTIME_DIR/*)
                  printf '%s/%s\n' "$runtime_dir" "''${configured_path#\$XDG_RUNTIME_DIR/}"
                  ;;
                /*)
                  printf '%s\n' "$configured_path"
                  ;;
                *)
                  printf '%s/%s\n' "$workdir" "$configured_path"
                  ;;
              esac
            }

            append_unique_path() {
              local -n paths="$1"
              local candidate="$2"
              local existing

              for existing in "''${paths[@]}"; do
                [ "$existing" = "$candidate" ] && return 0
              done
              paths+=("$candidate")
            }

            for configured_path in "''${configured_read_only_paths[@]}"; do
              resolved_path="$(resolve_path "$configured_path")"
              [ -e "$resolved_path" ] || continue
              append_unique_path resolved_read_only_paths "$resolved_path"
            done

            for configured_path in "''${configured_read_write_paths[@]}"; do
              resolved_path="$(resolve_path "$configured_path")"
              if [ ! -e "$resolved_path" ]; then
                printf '%s: read-write path does not exist: %s\n' \
                  ${escapedExecutableName} "$resolved_path" >&2
                exit 1
              fi
              append_unique_path resolved_read_write_paths "$resolved_path"
            done

            printf '%s: filesystem access\n' ${escapedExecutableName} >&2
            printf '  read-write:\n' >&2
            if [ "''${#resolved_read_write_paths[@]}" -eq 0 ]; then
              printf '    (none)\n' >&2
            else
              printf '    %s\n' "''${resolved_read_write_paths[@]}" >&2
            fi
            printf '  read-only:\n' >&2
            if [ "''${#resolved_read_only_paths[@]}" -eq 0 ]; then
              printf '    (none)\n' >&2
            else
              printf '    %s\n' "''${resolved_read_only_paths[@]}" >&2
            fi
          '';

          linuxLauncher = pkgs.writeShellApplication {
            name = executableName;
            passthru = {
              inherit shellOptions;
            }
            // passthru;
            runtimeInputs = runtimeInputs ++ [
              pkgs.bubblewrap
              pkgs.coreutils
              pkgs.gawk
            ];

            text = ''
              set -euo pipefail
              ${commonScript}

              path_is_covered_by() {
                local candidate="$1"
                shift
                local root

                for root in "$@"; do
                  case "$candidate" in
                    "$root"|"$root"/*)
                      return 0
                      ;;
                  esac
                done
                return 1
              }

              system_read_only_paths=()
              system_path_args=()
              for path in /nix /usr /bin /lib /lib64 /etc /sys; do
                [ -e "$path" ] || continue
                system_read_only_paths+=("$path")
                system_path_args+=(--ro-bind "$path" "$path")
              done

              sandbox_path_args=()
              network_args=( ${linuxNetworkArgs} )
              for path in "''${resolved_read_only_paths[@]}"; do
                if path_is_covered_by "$path" "''${system_read_only_paths[@]}"; then
                  continue
                fi
                sandbox_path_args+=(--ro-bind "$path" "$path")
              done
              for path in "''${resolved_read_write_paths[@]}"; do
                if [ "$path" = "/tmp" ]; then
                  continue
                fi
                sandbox_path_args+=(--bind "$path" "$path")
              done

              path_args=()
              while IFS= read -r path; do
                [ -d "$path" ] || continue
                if path_is_covered_by "$path" \
                  "''${system_read_only_paths[@]}" \
                  "''${resolved_read_only_paths[@]}" \
                  "''${resolved_read_write_paths[@]}"; then
                  continue
                fi
                path_args+=(--ro-bind "$path" "$path")
              done < <(
                printf '%s\n' "$PATH" | tr ':' '\n' | awk '!seen[$0]++'
              )

              command_args=()
              if ! path_is_covered_by "$command_path" \
                "''${system_read_only_paths[@]}" \
                "''${resolved_read_only_paths[@]}"; then
                command_args+=(--ro-bind "$command_path" "$command_path")
              fi

              exec ${pkgs.bubblewrap}/bin/bwrap \
                "''${system_path_args[@]}" \
                --proc /proc \
                --dev /dev \
                --tmpfs /tmp \
                "''${sandbox_path_args[@]}" \
                "''${path_args[@]}" \
                --chdir "$workdir" \
                "''${network_args[@]}" \
                --die-with-parent \
                --setenv HOME "$home_dir" \
                --setenv PATH "$PATH" \
                --setenv TMPDIR "$temp_dir" \
                --setenv XDG_RUNTIME_DIR "$runtime_dir" \
                "''${command_args[@]}" \
                -- \
                "$command_path" "$@"
            '';
          };

          darwinLauncher = pkgs.writeShellApplication {
            name = executableName;
            passthru = {
              inherit shellOptions;
            }
            // passthru;
            runtimeInputs = runtimeInputs ++ [ pkgs.coreutils ];

            text = ''
              set -euo pipefail
              ${commonScript}

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
              ${darwinNetworkRule}
              EOF

              sandbox_path_args=()
              sandbox_path_index=0
              metadata_path_index=0

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

              append_unique_path resolved_read_only_paths "$command_path"

              for path in "''${resolved_read_write_paths[@]}"; do
                compose_sandbox_config read-write "$path"
              done
              for path in "''${resolved_read_only_paths[@]}"; do
                compose_sandbox_config read-only "$path"
              done

              exec /usr/bin/sandbox-exec -f "$profile" \
                -D "home_dir=$home_dir" \
                "''${sandbox_path_args[@]}" \
                "$command_path" "$@"
            '';
          };
        in
        assert lib.assertMsg (lib.attrNames invalidEnvironmentNames == [ ]) (
          "mkAgentSandbox received invalid environment variable names: "
          + lib.concatStringsSep ", " (lib.attrNames invalidEnvironmentNames)
        );
        if pkgs.stdenv.hostPlatform.isDarwin then darwinLauncher else linuxLauncher;
    in
    {
      lib = {
        inherit mkAgentSandbox shellOptions;
      };

      formatter = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ] (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
