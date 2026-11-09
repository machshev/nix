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

  # Draconis (dragons) and its mob API, Creatura. Pinned to the ContentDB
  # release commits.
  creatura = pkgs.fetchFromGitHub {
    owner = "ElCeejo";
    repo = "creatura";
    rev = "4eb507cf2433f0787691f560842deea79a1666f4"; # 0.2.10
    hash = "sha256-JRnVfZaupzPUB3DQOtCyYZ2O6e/0WGi61/XVdkUbGqw=";
  };

  # Draconis targets Minetest Game and hardcodes some of its item names, which
  # Mineclonia doesn't alias: without this the forge recipes need a
  # nonexistent furnace and nests spawn without their gold/iron hoards.
  # Depending on mcl_core makes those nodes exist when mapgen.lua runs.
  draconis = pkgs.applyPatches {
    name = "draconis";
    src = pkgs.fetchFromGitHub {
      owner = "ElCeejo";
      repo = "draconis";
      rev = "beb0288295637f7faae8758519fc3d8584a4e003"; # 2.0.6
      hash = "sha256-Zk4aLgJH1GtIXdHQo2gl64KGuO+cW9ij9RXlVx4faSc=";
    };
    postPatch = ''
      substituteInPlace init.lua craftitems.lua \
        --replace-fail '"default:ice"' '"mcl_core:ice"'
      substituteInPlace init.lua craftitems.lua mapgen.lua \
        --replace-fail '"default:steelblock"' '"mcl_core:ironblock"'
      substituteInPlace craftitems.lua mapgen.lua \
        --replace-fail '"default:goldblock"' '"mcl_core:goldblock"'
      substituteInPlace craftitems.lua \
        --replace-fail '"default:furnace"' '"mcl_furnaces:furnace"'
      substituteInPlace nodes.lua \
        --replace-fail '"default:steel_ingot"' '"mcl_core:iron_ingot"'
      substituteInPlace mod.conf \
        --replace-fail "optional_depends = default," "optional_depends = default, mcl_core, mcl_furnaces,"
    '';
  };

  # Mods inside a game's mods/ directory are always enabled, so bundling them
  # avoids managing load_mod_* lines in the world's world.mt.
  mineclonia-modded = pkgs.runCommand "mineclonia-modded" {} ''
    cp -r ${mineclonia} $out
    chmod u+w $out/mods
    ln -s ${creatura} $out/mods/creatura
    ln -s ${draconis} $out/mods/draconis
  '';

  # LUANTI_GAME_PATH points at a directory of games, each named by its id.
  games = pkgs.linkFarm "luanti-games" {mineclonia = mineclonia-modded;};

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
