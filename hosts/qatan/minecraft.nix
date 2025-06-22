{
  pkgs-unstable,
  ...
}: {
  # manually installed ViaVersion and geysermc to get things going
  # TODO: look at https://github.com/Infinidoge/nix-minecraft/issues/68

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
      max-players = 5;
      motd = "NixOS Minecraft server!";
      white-list = false;
      allow-cheats = true;
    };
  };
}
