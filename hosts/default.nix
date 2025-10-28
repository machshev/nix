{
  inputs,
  nixpkgs,
  nixpkgs-unstable,
  machshev-pkgs,
  flake-utils,
  ...
}: let
  inherit (inputs) home-manager disko nixos-facter-modules sops-nix;
  # This could just be inputs.deploy-rs, but doing so will require rebuild instead of using binary cache.
  # See instruction from the upstream repo: https://github.com/serokell/deploy-rs
  deploy-rs.lib = flake-utils.lib.eachDefaultSystemMap (
    system:
      (import nixpkgs {
        inherit system;
        overlays = [
          inputs.deploy-rs.overlays.default
          (final: prev: {
            deploy-rs = {
              inherit (nixpkgs.legacyPackages.${prev.system}) deploy-rs;
              lib = prev.deploy-rs.lib;
            };
          })
        ];
      })
      .deploy-rs
      .lib
  );

  system = "x86_64-linux";
  lib = nixpkgs.lib;
  pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};

  user-helpers = import ../modules/users {inherit lib machshev-pkgs;};

  machines = ["gadol" "tzedef" "qatan" "tapuach" "avodah" "anan"];
in rec {
  nixosConfigurations = lib.genAttrs machines (name:
    lib.nixosSystem {
      specialArgs = {inherit inputs pkgs-unstable machshev-pkgs user-helpers;};
      modules = [
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
        ../modules/nixos
        ./${name}
        {config.facter.reportPath = ./${name}/facter.json;}
        nixos-facter-modules.nixosModules.facter
        home-manager.nixosModules.default
      ];
    });

  deploy = {
    nodes =
      builtins.mapAttrs (name: _: {
        hostname = name;
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.${nixosConfigurations.${name}.pkgs.system}.activate.nixos nixosConfigurations.${name};
        };
        interactiveSudo = true;
      }) {
        anan = {
          sshUser = "david";
        };
        qatan = {
          sshUser = "david";
        };
        gadol = {
          sshUser = "david";
        };
        tzedef = {
          sshUser = "david";
        };
        tapuach = {
          sshUser = "david";
        };
        avodah = {
          sshUser = "jamesm";
        };
      };
  };

  checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks deploy) deploy-rs.lib;
}
