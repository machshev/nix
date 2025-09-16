{
  pkgs,
  inputs,
  user-helpers,
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
    applyUdevRules = true;
    autoupdate.enable = true;
    closedFirmwareUpdates = true;
    graphics.enable = true;
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


  environment.systemPackages = with pkgs; [
    zoom-us
  ];

  system.stateVersion = "24.11";
}
