{
  description = "Shared CI for fnune's public repositories: a pinned Debian container with Nix, and release tools";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = {
    self,
    nixpkgs,
  }: let
    systems = ["x86_64-linux" "aarch64-linux"];
    forEachSystem = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

    toolsFor = pkgs: let
      tool = name: runtimeInputs:
        pkgs.writeShellApplication {
          inherit name runtimeInputs;
          text = builtins.readFile ./tools/${name}.sh;
          runtimeEnv = {
            DEFAULT_ACTIONLINT_CONFIG = "${./tools/actionlint.yaml}";
            DEFAULT_ZIZMOR_CONFIG = "${./tools/zizmor.yml}";
          };
        };
    in rec {
      check-changelog = tool "check-changelog" [pkgs.changie pkgs.diffutils pkgs.findutils pkgs.git pkgs.gnugrep];
      checksums = tool "checksums" [pkgs.coreutils pkgs.findutils];
      lint-workflows = tool "lint-workflows" [pkgs.actionlint pkgs.findutils pkgs.shellcheck pkgs.zizmor];
      publish-github = tool "publish-github" [pkgs.coreutils pkgs.findutils pkgs.gh release-notes];
      release-notes = tool "release-notes" [pkgs.coreutils pkgs.git pkgs.git-cliff pkgs.gnused];
      scan-secrets = tool "scan-secrets" [pkgs.gitleaks];
    };
  in {
    packages = forEachSystem (pkgs: let
      tools = toolsFor pkgs;
    in
      tools
      // {
        default = pkgs.symlinkJoin {
          name = "ci-tools";
          paths = builtins.attrValues tools;
        };
      });

    checks = forEachSystem (pkgs: let
      tools = self.packages.${pkgs.stdenv.hostPlatform.system};
      bats = pkgs.bats.withLibraries (libraries: [libraries.bats-support libraries.bats-assert]);
    in {
      lint =
        pkgs.runCommand "ci-lint" {
          nativeBuildInputs = [
            pkgs.action-validator
            pkgs.alejandra
            pkgs.deadnix
            pkgs.shellcheck
            pkgs.shfmt
            pkgs.statix
            tools.lint-workflows
          ];
        } ''
          export HOME=$TMPDIR
          cd ${self}
          shellcheck --shell=bash tools/*.sh tests/*.bash tests/*.bats
          shellcheck run.sh entry.sh
          shfmt --diff .
          alejandra --check --quiet .
          statix check .
          deadnix --fail .
          action-validator action.yml .github/workflows/*.yml
          lint-workflows
          touch $out
        '';

      tests =
        pkgs.runCommand "ci-tests" {
          nativeBuildInputs = [bats tools.default pkgs.changie pkgs.git pkgs.git-cliff];
        } ''
          export HOME=$TMPDIR
          bats ${./tests}
          touch $out
        '';
    });

    devShells = forEachSystem (pkgs: {
      default = pkgs.mkShell {
        packages = [self.packages.${pkgs.stdenv.hostPlatform.system}.default pkgs.changie pkgs.gitleaks pkgs.shellcheck pkgs.shfmt];
      };
    });

    formatter = forEachSystem (pkgs: pkgs.alejandra);
  };
}
