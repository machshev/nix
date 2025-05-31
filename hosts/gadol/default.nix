{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./fs.nix
  ];

  machshev = {
    hostName = "gadol";
    machineID = "127faeee905223190bb95dba67694307";
    user = {
      enable = true;
    };
    applyUdevRules = true;
    autoupdate.enable = true;
    closedFirmwareUpdates = true;
  };

  users.users.root.initialHashedPassword = "$6$z8fXf0P0ap18L20y$NCe1iQXlG.Rv.br/sAnj7cpIQk5pvpikddLfxQKebJU0xJhsGj9/Pyu.MQ2vW/9St7unvHQo5AoqsjUX8bqZl1";
  users.users.david.initialHashedPassword = "$6$vEy6OWDYzpTOg4ow$fHSBYDc4o0jl/lTJK11zBaYabTihXdQyP9VupPSh8V4McKpPiTjT8ljnNbTjMJoQ8jOipp11E2oqEhdQAkPhz1";

  virtualisation.podman.dockerCompat = lib.mkForce false;
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  environment.systemPackages = with pkgs; [docker-compose];
  users.users.david.extraGroups = ["docker"];
  system.stateVersion = "24.11";
}
