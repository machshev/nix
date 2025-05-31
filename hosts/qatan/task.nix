{
  ...
}: {
  networking.firewall.allowedTCPPorts = [
    10222 # taskchampion
  ];

  services.taskchampion-sync-server = {
    enable = true;
    port = 10222;
  };
}
