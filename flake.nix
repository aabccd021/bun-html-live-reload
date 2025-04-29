{

  nixConfig.allow-import-from-derivation = false;
  nixConfig.extra-substituters = [
    "https://cache.garnix.io"
    "https://nix-community.cachix.org"
  ];
  nixConfig.extra-trusted-public-keys = [
    "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.treefmt-nix.url = "github:numtide/treefmt-nix";
  inputs.bun2nix.url = "github:baileyluTCD/bun2nix";

  outputs = { self, ... }@inputs:
    let
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;

      nodeModules = inputs.bun2nix.lib.x86_64-linux.mkBunNodeModules (import ./bun.nix);

      treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";
        programs.prettier.enable = true;
        programs.nixpkgs-fmt.enable = true;
        programs.biome.enable = true;
        programs.shfmt.enable = true;
        settings.formatter.prettier.priority = 1;
        settings.formatter.biome.priority = 2;
        settings.global.excludes = [ "LICENSE" "*.ico" ];
      };

      tsc = pkgs.runCommand "tsc" { } ''
        cp -L ${./index.ts} ./index.ts
        cp -Lr ${./test} ./test
        cp -L ${./tsconfig.json} ./tsconfig.json
        cp -Lr ${nodeModules}/node_modules ./node_modules
        ${pkgs.typescript}/bin/tsc
        touch $out
      '';

      biome = pkgs.runCommand "biome" { } ''
        cp -L ${./biome.jsonc} ./biome.jsonc
        cp -L ${./index.ts} ./index.ts
        cp -Lr ${./test} ./test
        cp -L ${./package.json} ./package.json
        cp -L ${./tsconfig.json} ./tsconfig.json
        cp -Lr ${nodeModules}/node_modules ./node_modules
        ${pkgs.biome}/bin/biome check --error-on-warnings
        touch $out
      '';

      tests = pkgs.runCommand "tests"
        {
          buildInputs = [ pkgs.bun pkgs.musl ];
          env.PLAYWRIGHT_BROWSERS_PATH = pkgs.playwright.browsers;
        } ''
        cp -L ${./index.ts} ./index.ts
        cp -Lr ${./test} ./test
        cp -L ${./package.json} ./package.json
        cp -L ${./tsconfig.json} ./tsconfig.json
        cp -Lr ${nodeModules}/node_modules ./node_modules
        bun test
        touch $out
      '';

      publish = pkgs.writeShellApplication {
        name = "publish";
        text = ''
          published_version=$(npm view . version)
          current_version=$(${pkgs.jq}/bin/jq -r .version package.json)
          if [ "$published_version" = "$current_version" ]; then
            echo "Version $current_version is already published"
            exit 0
          fi
          echo "Publishing version $current_version"

          nix flake check
          NPM_TOKEN=''${NPM_TOKEN:-}
          if [ -n "$NPM_TOKEN" ]; then
            npm config set //registry.npmjs.org/:_authToken "$NPM_TOKEN"
          fi
          npm publish
        '';
      };

      devShell = pkgs.mkShellNoCC {
        shellHook = ''
          export PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright.browsers}
        '';
        buildInputs = [
          pkgs.bun
          pkgs.biome
          pkgs.typescript
          pkgs.vscode-langservers-extracted
          pkgs.nixd
          pkgs.typescript-language-server
        ];
      };

      packages = {
        formatting = treefmtEval.config.build.check self;
        tsc = tsc;
        biome = biome;
        nodeModules = nodeModules;
        publish = publish;
        tests = tests;
        bun2nix = inputs.bun2nix.packages.x86_64-linux.default;
      };

    in
    {

      checks.x86_64-linux = packages;

      packages.x86_64-linux = packages // rec {
        gcroot = pkgs.linkFarm "gcroot" packages;
        default = gcroot;
      };


      formatter.x86_64-linux = treefmtEval.config.build.wrapper;

      apps.x86_64-linux.publish = {
        type = "app";
        program = "${publish}/bin/publish";
      };

      devShells.x86_64-linux.default = devShell;
    };
}
