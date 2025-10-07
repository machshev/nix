# SPDX-License-Identifier: MIT
{
  nixpkgs,
  flake-utils,
  nvf,
  ...
}:
flake-utils.lib.eachDefaultSystemMap (system: let
  pkgs = import nixpkgs {
    inherit system;
  };
in {
  dev-udev-rules = pkgs.callPackage ./dev-udev-rules {};
  neovim =
    (nvf.lib.neovimConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        ./nvf
      ];
    })
    .neovim;
})
