{machshev-pkgs, ...}: {
  imports = [
    ./nix.nix
    ./common.nix
    ./boot.nix
    ./graphics.nix
    ./games.nix
    ./net.nix
    ./dev-udev-rules.nix
    ./printing.nix
    ./sound.nix
    ./auto-update.nix
    ./jlink.nix
    ./display.nix
    ./security.nix
    ./btrfs.nix
    ./sdr.nix
  ];
  options = {
    machshev = {
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
