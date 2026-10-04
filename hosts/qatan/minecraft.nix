{
  config,
  pkgs,
  pkgs-unstable,
  ...
}: {

  networking.firewall.allowedUDPPorts = [
    19132 # Minecraft bedrock (GeyserMC)
  ];

  services.minecraft-server = {
    enable = true;
    eula = true;
    openFirewall = true;
    package = pkgs-unstable.papermc;
    declarative = true;
    #whitelist = {
    #  RockCloud678071 = "2535435978056163";
    #  DevoutAsp7316 = "2535413609540785";
    #};
    serverProperties = {
      difficulty = 3;
      max-players = 6;
      motd = "NixOS Minecraft server!";
      white-list = false;
      allow-cheats = true;
    };
  };

  systemd.services.minecraft-plugin-update = {
    description = "Update Minecraft plugins to their latest upstream builds";
    wants = ["network-online.target"];
    after = ["network-online.target"];
    path = with pkgs; [bash coreutils curl diffutils unzip systemd];
    environment.MINECRAFT_DATA_DIR = config.services.minecraft-server.dataDir;
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      TimeoutStartSec = "15min";
      UMask = "0077";
    };
    script = builtins.readFile ./update-minecraft-plugins.sh;
  };

  systemd.timers.minecraft-plugin-update = {
    description = "Check for Minecraft plugin updates daily";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*-*-* 04:00:00";
      RandomizedDelaySec = "15min";
      Persistent = true;
    };
  };
}
