{
  description = "Idle-timeout wrapper (upto)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          package = pkgs.stdenv.mkDerivation {
            pname = "upto";
            version = "0.1.0";
            src = ./.;

            dontBuild = true;
            installPhase = ''
              install -Dm755 ${./upto.sh} $out/bin/upto
            '';
          };
        in {
          default = package;
        });
      packageFor = system: packages.${system}.default;
    in {
      packages = packages;

      defaultPackage = forAllSystems (system: packageFor system);

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${packageFor system}/bin/upto";
        };
      });

      defaultApp = forAllSystems (system: {
        type = "app";
        program = "${packageFor system}/bin/upto";
      });
    };
}
