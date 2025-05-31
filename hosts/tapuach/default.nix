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
    hostName = "tapuach";
    machineID = "586e11ccadb426b529218dc46831ebde";
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
  users.users.josephm.initialHashedPassword = "$6$vEy6OWDYzpTOg4ow$fHSBYDc4o0jl/lTJK11zBaYabTihXdQyP9VupPSh8V4McKpPiTjT8ljnNbTjMJoQ8jOipp11E2oqEhdQAkPhz1";


  system.stateVersion = "25.05";
}
