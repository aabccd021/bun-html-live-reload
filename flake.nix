{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = { nixpkgs, ... }: 
  let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;

  in
  {

    devShells.x86_64-linux.default = pkgs.mkShellNoCC {
      shellHook = ''
        export PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers-chromium}
      '';
      buildInputs = [
        pkgs.bun
      ];
    };

  };
}
