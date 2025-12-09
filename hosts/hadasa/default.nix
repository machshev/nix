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
    hostName = "hadasa";
    machineID = "efbd05b7865e4152b98207339f6a2cec";
    applyUdevRules = true;
    autoupdate.enable = false;
    nixAutoGC = false;
    closedFirmwareUpdates = true;
    graphics.enable = true;
    vulkan = false;
    games = {
      enable = true;
    };
  };

  users.users.david = user-helpers.mkUserCfg {
    inherit pkgs;
    name = "david";
  };

  users.users.lydiam = user-helpers.mkUserCfg {
    inherit pkgs;
    name = "lydiam";
  };

  home-manager = user-helpers.mkHomeManager {
    inherit inputs;
    users = ["david" "lydiam"];
  };

  # Workstation set default root password - MUST be changed on first login
  users.users.root.initialHashedPassword = "$6$z8fXf0P0ap18L20y$NCe1iQXlG.Rv.br/sAnj7cpIQk5pvpikddLfxQKebJU0xJhsGj9/Pyu.MQ2vW/9St7unvHQo5AoqsjUX8bqZl1";

  system.stateVersion = "25.05";
}
