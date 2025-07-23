{
  description =
    "A gamescope wrapper that automatically sets the gamescope arguments and environment variables based on for your display settings.";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable"; };

  outputs = { self, nixpkgs }: {

    packages.x86_64-linux =
      let pkgs = import nixpkgs { system = "x86_64-linux"; };
      in rec {
        default = gamedownsights;
        gamedownsights = pkgs.stdenv.mkDerivation {
          name = "gamedownsights";
          buildInputs = with pkgs; [
            bash
            gawk
            yq 
          ];

          src = ./.;

          unpackPhase = ''
            mkdir -p $out/bin
            cp $src/*.sh $out/
            cp -R $src/bin/* $out/bin/
            chmod +x $out/bin/*
          '';
        };
      };

  };
}
