{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.bash
    pkgs.python313Packages.pyppeteer
    pkgs.python312
    pkgs.glib
    pkgs.glib.out
    pkgs.chromium
  ];
  shellHook = ''
    export PUPPETEER_EXECUTABLE_PATH=${pkgs.chromium}/bin/chromium
  '';
}
