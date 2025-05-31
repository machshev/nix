# SPDX-License-Identifier: MIT
{
  nixpkgs,
  flake-utils,
  ...
}: flake-utils.lib.eachDefaultSystemMap (system: let
    pkgs = import nixpkgs {
      inherit system;
    };
  in {
  dev-udev-rules = pkgs.callPackage ./dev-udev-rules {};
})

