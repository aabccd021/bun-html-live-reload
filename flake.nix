{

  nixConfig.allow-import-from-derivation = false;

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.treefmt-nix.url = "github:numtide/treefmt-nix";

  outputs =
    { self, ... }@inputs:
    let
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;

      treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
        programs.biome.enable = true;
        programs.biome.formatUnsafe = true;
        programs.biome.settings.formatter.indentStyle = "space";
        programs.biome.settings.formatter.lineWidth = 100;
        programs.shfmt.enable = true;
        settings.global.excludes = [ "LICENSE" ];
      };

      node_modules = import ./node_modules.nix { pkgs = pkgs; };

      packages.check-tsc = pkgs.runCommand "tsc" { } ''
        cp -L ${./index.ts} ./index.ts
        cp -Lr ${./test} ./test
        cp -L ${./tsconfig.json} ./tsconfig.json
        cp -Lr ${node_modules} ./node_modules
        ${pkgs.typescript}/bin/tsc
        touch $out
      '';

      browsers = pkgs.playwright.browsers.overrideAttrs {
        withChromium = false;
        withFirefox = false;
        withWebkit = false;
        withFfmpeg = false;
        withChromiumHeadlessShell = true;
      };

      mkTest =
        testFile:
        pkgs.runCommand "tests"
          {
            buildInputs = [
              pkgs.bun
              pkgs.musl
            ];
            env.PLAYWRIGHT_BROWSERS_PATH = browsers;
          }
          ''
            cp -L ${./index.ts} ./index.ts
            cp -Lr ${./test} ./test
            cp -L ${./package.json} ./package.json
            cp -L ${./tsconfig.json} ./tsconfig.json
            cp -Lr ${node_modules} ./node_modules
            bun test ./test/${testFile}.test.ts
            touch $out
          '';

      packages.check-formatting = treefmtEval.config.build.check self;
      packages.test-no-autoreload = mkTest "no-autoreload";
      packages.test-reload = mkTest "reload";

    in
    {

      packages.x86_64-linux = packages;
      checks.x86_64-linux = packages;
      formatter.x86_64-linux = treefmtEval.config.build.wrapper;
    };
}
