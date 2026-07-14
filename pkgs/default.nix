# SPDX-License-Identifier: MIT
{
  inputs,
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
  haqor = inputs.haqor-core.packages.${system}.haqor;
  haqor-cli = inputs.haqor-core.packages.${system}.haqor-cli;
  haqor-admin = inputs.haqor-core.packages.${system}.haqor-admin;
  haqor-core = inputs.haqor-core.packages.${system}.haqor-core;
  haqor-db-gen = inputs.haqor-core.packages.${system}.haqor-db-gen;
  haqor-morphology = inputs.haqor-core.packages.${system}.haqor-morphology;
  haqor-sync-server = inputs.haqor-core.packages.${system}.haqor-sync-server;
  neovim =
    (nvf.lib.neovimConfiguration {
      inherit pkgs;
      modules = [
        ./nvf
      ];
    })
    .neovim;
})
