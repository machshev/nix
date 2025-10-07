# SPDX-License-Identifier: MIT
{
  description = "Dev environment Nix Packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

    # For command-not-found, need this since we get rid of all channels
    flake-programs-sqlite = {
      url = "github:wamserma/flake-programs-sqlite";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "flake-utils";
    };

    nvf.url = "github:notashelf/nvf";

    lowrisc-it = {
      url = "git+ssh://git@github.com/lowRISC/lowrisc-it";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lowrisc-nix = {
      url = "github:lowRISC/lowrisc-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    flake-utils,
    deploy-rs,
    nvf,
    ...
  } @ inputs: let
    machshev-pkgs = import ./pkgs {
      inherit
        inputs
        nixpkgs
        nixpkgs-unstable
        flake-utils
        nvf
        ;
    };

    machines = import ./hosts {
      inherit
        inputs
        nixpkgs
        nixpkgs-unstable
        flake-utils
        machshev-pkgs
        deploy-rs
        ;
    };
  in {
    packages = machshev-pkgs;

    # system config
    nixosConfigurations = machines.nixosConfigurations;
    deploy = machines.deploy;

    # dev shells
    devShells = import ./devshells.nix {
      inherit
        inputs
        nixpkgs
        nixpkgs-unstable
        flake-utils
        machshev-pkgs
        ;
    };

    checks = machines.checks;

    # nix fmt
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
  };
}
