# SPDX-License-Identifier: MIT
{
  nixpkgs-unstable,
  flake-utils,
  nvf,
  ...
}:
flake-utils.lib.eachDefaultSystemMap (system: let
  pkgs = import nixpkgs-unstable {
    inherit system;
  };
in {
  dev-udev-rules = pkgs.callPackage ./dev-udev-rules {};
  neovim =
    (nvf.lib.neovimConfiguration {
      inherit pkgs;
      modules = [
        ./nvf
      ];
    })
    .neovim;
})
