{
  ...
}: {
  services.taskchampion-sync-server = {
    enable = true;
    host = "0.0.0.0";
    port = 10222;
    openFirewall = true;
  };
}
