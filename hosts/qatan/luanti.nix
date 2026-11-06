{
  pkgs,
  ...
}: let
  # Luanti is engine-only since 5.8 and nixpkgs packages no games, so fetch
  # Mineclonia (a Minecraft-like survival game) ourselves. Clients don't need
  # it installed: they download the game's media from the server on joining.
  mineclonia = pkgs.fetchFromGitea {
    domain = "codeberg.org";
    owner = "mineclonia";
    repo = "mineclonia";
    rev = "0.124.1";
    hash = "sha256-ur4LhJ92rk5JQa1PzpGY/5cKCjayLUIh5M64ONtsAGo=";
  };

  # LUANTI_GAME_PATH points at a directory of games, each named by its id.
  games = pkgs.linkFarm "luanti-games" {inherit mineclonia;};

  port = 30000;
in {
  services.minetest-server = {
    enable = true;
    gameId = "mineclonia";
    inherit port;
    world = "/var/lib/minetest/.minetest/worlds/mineclonia";
    config = {
      # Admin: this player gets every privilege. Luanti names are
      # case-sensitive, so log in as exactly "david". Anyone can claim the
      # name first if it's unregistered, so join once soon after deploying.
      name = "david";
      server_name = "NixOS Luanti server";
      server_description = "Mineclonia on qatan";
      motd = "Welcome to the NixOS Luanti server!";
      max_users = 10;
      # Don't list on the public server list at servers.luanti.org.
      server_announce = "false";
      creative_mode = "false";
      enable_damage = true;
      # Strings, not bools: the module renders false as an empty value, which
      # Luanti ignores in favour of the default (PvP defaults to on).
      enable_pvp = "false";
    };
  };

  systemd.services.minetest-server.environment.LUANTI_GAME_PATH = "${games}";

  # Luanti uses a single UDP port; the module doesn't open it itself.
  networking.firewall.allowedUDPPorts = [port];
}
