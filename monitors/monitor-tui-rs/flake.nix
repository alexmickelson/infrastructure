{
  description = "GNOME Monitor TUI in Rust with runtime deps";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    naersk.url = "github:nix-community/naersk";
  };

  outputs = { self, nixpkgs, naersk }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          naersk' = pkgs.callPackage naersk { };
          runtimeDeps = with pkgs; [
            gnome-monitor-config
            dialog
            newt
            xorg.xrandr
            bash
            coreutils
          ];
        in {
          default = naersk'.buildPackage {
            pname = "monitor-tui";
            version = "0.1.0";
            src = ./.;
            nativeBuildInputs = [ pkgs.makeWrapper ];
            buildInputs = [ ];
            postInstall = ''
              wrapProgram $out/bin/monitor-tui \
                --prefix PATH : ${pkgs.lib.makeBinPath runtimeDeps}
            '';
          };
        });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/monitor-tui";
        };
      });

      devShells = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; }; in {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              rustc cargo rustfmt clippy
              gnome-monitor-config dialog newt xorg.xrandr bash coreutils
            ];
          };
        }
      );
    };
}
