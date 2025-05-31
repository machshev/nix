{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./fs.nix
  ];

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages;

  machshev = {
    hostName = "tzedef";
    machineID = "ad2793eacb8d53aacc492bb5678d6821";
    user = {
      enable = true;
    };
    applyUdevRules = true;
    autoupdate.enable = true;
    closedFirmwareUpdates = true;
    graphics.enable = true;
  };

  users.users.root.initialHashedPassword = "$6$z8fXf0P0ap18L20y$NCe1iQXlG.Rv.br/sAnj7cpIQk5pvpikddLfxQKebJU0xJhsGj9/Pyu.MQ2vW/9St7unvHQo5AoqsjUX8bqZl1";
  users.users.david.initialHashedPassword = "$6$vEy6OWDYzpTOg4ow$fHSBYDc4o0jl/lTJK11zBaYabTihXdQyP9VupPSh8V4McKpPiTjT8ljnNbTjMJoQ8jOipp11E2oqEhdQAkPhz1";

  system.stateVersion = "24.11";
}
