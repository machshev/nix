{
  config,
  inputs,
  user-helpers,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./fs.nix
    ./ha.nix
    ./haqor-sync.nix
    ./task.nix
    ./minecraft.nix
    ./pumpkin.nix
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets."z2m.yaml" = {
      format = "yaml";
      sopsFile = ./z2m-secrets.yaml;
      key = "";
      owner = "zigbee2mqtt";
      restartUnits = ["zigbee2mqtt.service"];
    };
    secrets."mosquitto/root" = {};
    secrets."mosquitto/z2m" = {};
    secrets."mosquitto/hass" = {
      restartUnits = ["home-assistant.service"];
    };
    secrets."mosquitto/chimum" = {};
  };

  machshev = {
    hostName = "qatan";
    machineID = "92fe87dfa38d10d30eda16a267693da2";
    applyUdevRules = true;
    autoupdate.enable = true;
    nixAutoGC = true;
    closedFirmwareUpdates = true;
    nebula.enable = true;
  };

  boot.loader.systemd-boot.configurationLimit = 3;

  # Prune by generation count instead of age, retaining three system
  # generations including the current one before collecting unused paths.
  nix.gc.options = lib.mkForce "";
  systemd.services.nix-gc.preStart = ''
    ${config.nix.package}/bin/nix-env --profile /nix/var/nix/profiles/system --delete-generations +3
  '';

  users.users.david = user-helpers.mkUserCfg {
    inherit pkgs;
    name = "david";
  };

  home-manager = user-helpers.mkHomeManager {
    inherit inputs;
    users = ["david"];
  };

  # Server is accessed via ssh key only, so there are no passwords set
  security.sudo.wheelNeedsPassword = false;

  # Prevent gdm from suspending the server
  services.xserver.displayManager.gdm.autoSuspend = false;
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;

  # WoL enable
  networking.interfaces.enp3s0.wakeOnLan.enable = true;
  networking.interfaces.enp3s0.useDHCP = true;

  # Disable emergency mode for server
  boot.initrd.systemd.emergencyAccess = false;
  systemd.enableEmergencyMode = false;

  # Disable waitonline - workaround until working config found
  systemd.network.wait-online.enable = lib.mkForce false;

  system.stateVersion = "24.11";
}
