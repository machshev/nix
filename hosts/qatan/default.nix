{
  inputs,
  user-helpers,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./fs.nix
    ./ha.nix
    ./task.nix
  ];

  machshev = {
    hostName = "qatan";
    machineID = "92fe87dfa38d10d30eda16a267693da2";
    applyUdevRules = true;
    autoupdate.enable = true;
    closedFirmwareUpdates = true;
  };

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

  networking.firewall.allowedUDPPorts = [
    19132 # Minecraft
  ];

  virtualisation.oci-containers.containers = {
    minecraft = {
      environment = {
        ALLOW_CHEATS = "true";
        EULA = "TRUE";
        DIFFICULTY = "1";
        SERVER_NAME = "Qatan";
        TZ = "Europe/London";
        VERSION = "LATEST";
        ALLOW_LIST_USERS = "JEMcCorrie:2535435978056163,RockCloud678071:2535435978056163,DevoutAsp7316:2535413609540785";
        OPS = "JEMcCorrie:2535435978056163,RockCloud678071:2535435978056163,DevoutAsp7316:2535413609540785";
      };
      image = "itzg/minecraft-bedrock-server";
      ports = ["0.0.0.0:19132:19132/udp"];
      volumes = ["/srv/minecraft/:/data"];
    };
  };

  services.rke2 = {
    enable = true;
  };

  system.stateVersion = "24.11";
}
