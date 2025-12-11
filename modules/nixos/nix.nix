{
  config,
  inputs,
  lib,
  ...
}:
with lib; {
  imports = [
    inputs.flake-programs-sqlite.nixosModules.programs-sqlite
  ];

  options = {
    machshev.nixAutoGC = mkOption {
      type = types.bool;
      default = false;
      description = "Enable nix auto gc.";
    };
  };

  config = {
    # Enable flakes + new nix command
    nix.settings = {
      experimental-features = ["nix-command" "flakes"];
      trusted-users = ["root" "@wheel"];
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
        "https://nix-cache.lowrisc.org/public/"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      flake-registry = "";
    };

    nix.channel.enable = false;

    nixpkgs.config.allowUnfree = true;

    programs.git.enable = lib.mkDefault true;
    programs.nix-ld.enable = true;

    # with channels disabled we need a replacement for command-not-found as fish
    # uses it.
    programs-sqlite.enable = config.programs.command-not-found.enable;

    nix.gc = mkIf config.machshev.nixAutoGC {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    # nix.settings.auto-optimise-store = true;
    nix.optimise = mkIf config.machshev.nixAutoGC {
      automatic = true;
      dates = ["weekly"];
    };
  };
}
