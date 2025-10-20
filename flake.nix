{
  description = "Idle-timeout wrapper (upto)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in {
      packages.x86_64-linux.default = pkgs.stdenv.mkDerivation {
        pname = "upto";
        version = "0.1.0";
        src = ./.;

        installPhase = ''
          mkdir -p $out/bin
          cp upto $out/bin/upto
          chmod +x $out/bin/upto
        '';
      };

      apps.x86_64-linux.default = {
        type = "app";
        program = "${self.packages.x86_64-linux.default}/bin/upto";
      };
    };
}

