{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    build-node-modules.url = "github:aabccd021/build-node-modules";
  };


  outputs = { self, nixpkgs, treefmt-nix, build-node-modules }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      nodeModules = build-node-modules.lib.buildNodeModules pkgs ./package.json ./package-lock.json;

      treefmtEval = treefmt-nix.lib.evalModule pkgs {
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
        cp -Lr ${nodeModules} ./node_modules
        ${pkgs.typescript}/bin/tsc
        touch $out
      '';

      biome = pkgs.runCommand "biome" { } ''
        cp -L ${./biome.jsonc} ./biome.jsonc
        cp -L ${./index.ts} ./index.ts
        cp -Lr ${./test} ./test
        cp -L ${./package.json} ./package.json
        cp -L ${./tsconfig.json} ./tsconfig.json
        cp -Lr ${nodeModules} ./node_modules
        ${pkgs.biome}/bin/biome check --error-on-warnings
        touch $out
      '';

      tests = pkgs.runCommand "tests"
        {
          buildInputs = [ pkgs.bun pkgs.musl ];
          env.PLAYWRIGHT_BROWSERS_PATH = pkgs.playwright-driver.browsers-chromium;
        } ''
        cp -L ${./index.ts} ./index.ts
        cp -Lr ${./test} ./test
        cp -L ${./package.json} ./package.json
        cp -L ${./tsconfig.json} ./tsconfig.json
        cp -Lr ${nodeModules} ./node_modules
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

      packages = {
        formatting = treefmtEval.config.build.check self;
        tsc = tsc;
        biome = biome;
        nodeModules = nodeModules;
        publish = publish;
        tests = tests;
      };

      gcroot = packages // {
        gcroot = pkgs.linkFarm "gcroot" packages;
      };
    in
    {

      checks.x86_64-linux = gcroot;

      packages.x86_64-linux = gcroot;

      formatter.x86_64-linux = treefmtEval.config.build.wrapper;

      apps.x86_64-linux.publish = {
        type = "app";
        program = "${publish}/bin/publish";
      };
    };
}
