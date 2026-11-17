let
  flake = builtins.getFlake "path:${toString ./.}";
  pkgs = flake.inputs.nixpkgs.legacyPackages.${builtins.currentSystem};
in
  pkgs.runCommand "sandbox-${toString builtins.currentTime}" {} ''
    test ! -e /etc/os-release
    touch $out
  ''
