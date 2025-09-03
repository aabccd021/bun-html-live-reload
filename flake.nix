{

  nixConfig.allow-import-from-derivation = false;

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.treefmt-nix.url = "github:numtide/treefmt-nix";

  outputs =
    { self, ... }@inputs:
    let
      lib = inputs.nixpkgs.lib;

      collectInputs =
        is:
        pkgs.linkFarm "inputs" (
          builtins.mapAttrs (
            name: i:
            pkgs.linkFarm name {
              self = i.outPath;
              deps = collectInputs (lib.attrByPath [ "inputs" ] { } i);
            }
          ) is
        );

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

      formatter = treefmtEval.config.build.wrapper;

      node_modules = import ./node_modules.nix { pkgs = pkgs; };

      tsc = pkgs.runCommand "tsc" { } ''
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

      publish = pkgs.writeShellApplication {
        name = "publish";
        runtimeInputs = [
          pkgs.jq
          pkgs.bun
          pkgs.curl
        ];
        text = ''
          repo_root=$(git rev-parse --show-toplevel)
          current_version=$(jq -r .version "$repo_root/package.json")
          name=$(jq -r .name "$repo_root/package.json")
          published_version=$(curl -s "https://registry.npmjs.org/$name" | jq -r '.["dist-tags"].latest')
          if [ "$published_version" = "$current_version" ]; then
            echo "Version $current_version is already published"
            exit 0
          fi
          nix flake check
          bun publish
        '';
      };

      devShells.default = pkgs.mkShellNoCC {
        shellHook = ''
          export PLAYWRIGHT_BROWSERS_PATH=${browsers}
        '';
        buildInputs = [
          pkgs.bun
          pkgs.typescript
          pkgs.vscode-langservers-extracted
          pkgs.nixd
          pkgs.typescript-language-server
        ];
      };

      packages = devShells // {
        formatting = treefmtEval.config.build.check self;
        formatter = formatter;
        allInputs = collectInputs inputs;
        tsc = tsc;
        publish = publish;
        test-no-autoreload = mkTest "no-autoreload";
        test-reload = mkTest "reload";
      };

    in
    {

      packages.x86_64-linux = packages // rec {
        gcroot = pkgs.linkFarm "gcroot" packages;
        default = gcroot;
      };

      checks.x86_64-linux = packages;
      formatter.x86_64-linux = formatter;
      devShells.x86_64-linux = devShells;
    };
}
