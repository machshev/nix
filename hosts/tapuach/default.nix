{
  inputs,
  user-helpers,
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
    applyUdevRules = true;
    autoupdate.enable = true;
    closedFirmwareUpdates = true;
    graphics.enable = true;
    games = {
      enable = true;
      steam.enable = true;
    };
    sdr = true;
  };

  users.users.david = user-helpers.mkUserCfg {
    inherit pkgs;
    name = "david";
  };

  users.users.josephm = user-helpers.mkUserCfg {
    inherit pkgs;
    name = "josephm";
  };

  home-manager = user-helpers.mkHomeManager {
    inherit inputs;
    users = ["david" "josephm"];
  };

  # Workstation set default root password - MUST be changed on first login
  users.users.root.initialHashedPassword = "$6$z8fXf0P0ap18L20y$NCe1iQXlG.Rv.br/sAnj7cpIQk5pvpikddLfxQKebJU0xJhsGj9/Pyu.MQ2vW/9St7unvHQo5AoqsjUX8bqZl1";

  system.stateVersion = "25.05";
}
