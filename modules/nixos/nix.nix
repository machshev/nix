{
  config,
  inputs,
  lib,
  ...
}: {
  imports = [
    inputs.flake-programs-sqlite.nixosModules.programs-sqlite
  ];

  options = {
  };

  config = {
    # Enable flakes + new nix command
    nix.settings.experimental-features = ["nix-command" "flakes"];
    nix.settings.trusted-users = ["root" "@wheel"];

    nix.settings.substituters = [
      "https://cache.nixos.org/"
      "https://nix-cache.lowrisc.org/public/"
    ];

    nix.settings.flake-registry = "";
    nix.channel.enable = false;

    programs.git.enable = lib.mkDefault true;

    # with channels disabled we need a replacement for command-not-found as fish
    # uses it.
    programs-sqlite.enable = config.programs.command-not-found.enable;

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    # nix.settings.auto-optimise-store = true;
    nix.optimise = {
      automatic = true;
      dates = ["weekly"];
    };
  };
}
