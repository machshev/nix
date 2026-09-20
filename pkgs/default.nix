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
    config.allowUnfreePredicate = pkg:
      builtins.elem (nixpkgs-unstable.lib.getName pkg) [
        "midtown-madness-2"
        "midtown-madness-2-data"
        "midtown-madness-2-directplay"
      ];
    overlays = [
      # cpplint's test suite fails on newer Pythons: codecs.open() now emits
      # a DeprecationWarning that leaks into stderr, breaking tests that
      # assert stderr is empty. Not our bug to fix; skip checks.
      (final: prev: {
        cpplint = prev.cpplint.overridePythonAttrs (_: {doCheck = false;});
      })
    ];
  };
in
  {
    dev-udev-rules = pkgs.callPackage ./dev-udev-rules {};
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
  }
  // pkgs.lib.optionalAttrs (system == "x86_64-linux") {
    # The desktop app. Upstream publishes a Linux bundle for x86_64 only.
    haqor = pkgs.callPackage ./haqor {};
    midtown-madness-2 = pkgs.callPackage ./midtown-madness-2 {};
  })
