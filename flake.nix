{
  description = "IaC management for dex IdP";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, utils, ...}:
    utils.lib.eachDefaultSystem (system:
      let 
        pkgs = nixpkgs.legacyPackages.${system};
        devdeps = with pkgs; [
          terraform_1
          (google-cloud-sdk.withExtraComponents (with google-cloud-sdk.components; [
            cloud-run-proxy
          ]))
          grpcurl
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = devdeps;
        };
      }
    );
}
