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
    overlays = [
      # cpplint's test suite fails on newer Pythons: codecs.open() now emits
      # a DeprecationWarning that leaks into stderr, breaking tests that
      # assert stderr is empty. Not our bug to fix; skip checks.
      (final: prev: {
        cpplint = prev.cpplint.overridePythonAttrs (_: {doCheck = false;});
      })
    ];
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
