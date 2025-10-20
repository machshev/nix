{
  inputs,
  pkgs,
  user-helpers,
  lib,
  ...
}: {
  imports = [
    ./fs.nix
  ];

  machshev = {
    hostName = "gadol";
    machineID = "127faeee905223190bb95dba67694307";
    applyUdevRules = true;
    autoupdate.enable = true;
    closedFirmwareUpdates = true;
    # graphics.nvidia = true;
    games = {
      enable = true;
      steam.enable = true;
    };
    wireshark = true;
  };

  users.users.david = user-helpers.mkUserCfg {
    inherit pkgs;
    name = "david";
  };

  home-manager = user-helpers.mkHomeManager {
    inherit inputs;
    users = ["david"];
  };

  users.users.root.initialHashedPassword = "$6$z8fXf0P0ap18L20y$NCe1iQXlG.Rv.br/sAnj7cpIQk5pvpikddLfxQKebJU0xJhsGj9/Pyu.MQ2vW/9St7unvHQo5AoqsjUX8bqZl1";

  virtualisation.podman.dockerCompat = lib.mkForce false;
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  environment.systemPackages = with pkgs; [
    docker-compose
  ];

  system.stateVersion = "24.11";
}
