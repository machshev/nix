{
  machshev-pkgs,
  lib,
  ...
}: {
  imports = [
    ./auto-update.nix
    ./boot.nix
    ./btrfs.nix
    ./common.nix
    ./dev-udev-rules.nix
    ./display.nix
    ./games.nix
    ./graphics.nix
    ./jlink.nix
    ./net.nix
    ./nix.nix
    ./printing.nix
    ./sdr.nix
    ./security.nix
    ./sound.nix
    ./vps.nix
  ];
  options = {
    machshev = {
      server = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Machine is a server.";
      };
    };
  };
  config = {
    nixpkgs.overlays = [
      # repositories so they can be used in modules.
      (final: prev: {
        machshev = machshev-pkgs.${prev.system};
      })
    ];
  };
}
