{
  description = "Printer Server Flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };
  outputs = { self, nixpkgs, ... }: 
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      myPython = pkgs.python3.withPackages (python-pkgs: with pkgs; [
        python312Packages.fastapi
        python312Packages.fastapi-cli
        python312Packages.pycups
        python312Packages.python-multipart
        python312Packages.uvicorn
      ]);
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          python312Packages.fastapi
          python312Packages.fastapi-cli
          python312Packages.pycups
          python312Packages.python-multipart
          python312Packages.uvicorn
        ];
      };

      packages.${system} = rec {
        fastapi-server = pkgs.writeShellScriptBin "start-server" ''
          ${myPython}/bin/fastapi run ${self}/src/print_api.py
        '';

        default = fastapi-server;
      };
      
    };
}