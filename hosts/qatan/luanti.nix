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
      # Mineclonia's per-player creative mode requires player names, not
      # ObjectRefs. Passing the object crashes target selection, feeding
      # dragons/wyverns and picking up eggs.
      substituteInPlace api/behaviors.lua \
        --replace-fail 'minetest.is_creative_enabled(target)' 'minetest.is_creative_enabled(target:get_player_name())'
      substituteInPlace api/api.lua \
        --replace-fail 'minetest.is_creative_enabled(player)' 'minetest.is_creative_enabled(player:get_player_name())'
      substituteInPlace craftitems.lua \
        --replace-fail 'minetest.is_creative_enabled(clicker)' 'minetest.is_creative_enabled(clicker:get_player_name())'
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

  # Release zips from ContentDB (content.luanti.org); upload URLs are
  # immutable per release. Some zips are flat rather than wrapped in a
  # directory, hence stripRoot.
  contentdb = {
    file,
    hash,
    stripRoot ? true,
  }:
    pkgs.fetchzip {
      url = "https://cdn.content.luanti.org/uploads/${file}.zip";
      inherit hash stripRoot;
    };

  # Mods keyed by their mod name (the directory name must match mod.conf), or
  # by modpack name for modpacks.
  mods = {
    inherit creatura draconis;

    # New biomes, blocks and items. Only affects newly generated chunks.
    everness = contentdb {
      file = "86b30e742e"; # 3.4.8
      hash = "sha256-wkVs9adjgt2v/9YbJo1vkHVn7q6QuwTqAaMEoyWbt9s=";
      stripRoot = false;
    };

    # Crops, trees, bees, ice fishing, composter and so on. Some of its
    # Mineclonia item names are wrong: without this the stove and fruit bowl
    # are uncraftable, and iced coffee from snowballs and drying sweet
    # berries don't work.
    x_farming = pkgs.applyPatches {
      name = "x_farming";
      src = contentdb {
        file = "95bbf237af"; # 4.3.5
        hash = "sha256-WujpTax2lZR6bBH/TpLQ4Z32azDb4C/4hOMmJ/SsSKs=";
        stripRoot = false;
      };
      postPatch = ''
        substituteInPlace crafting.lua \
          --replace-fail "'default:furnace'" "'mcl_furnaces:furnace'" \
          --replace-fail "'mcl_core:sweet_berries'" "'mcl_farming:sweet_berry'" \
          --replace-fail "'mcl_core:snowball'" "'mcl_throwing:snowball'"
        substituteInPlace drying_rack.lua \
          --replace-fail "'mcl_farming:sweet_berries'" "'mcl_farming:sweet_berry'"
      '';
    };

    # Furniture and decorations; depends on mcl_cozy.
    mcl_decor = contentdb {
      file = "e75cbf5ef7"; # 2.0.1
      hash = "sha256-QU45D9LRaZ2CpFWijY7OfsghovneMguzf2PZcQpfv9E=";
    };

    # Sit and lie down (/sit, /lay, or right-click a block).
    mcl_cozy = contentdb {
      file = "4140e25f4b"; # 3.3.1
      hash = "sha256-Cq8HMSOCavF0AGOZf9ZD0VXKQdR2/b+F/+8OlQNNGo0=";
    };

    # Aircraft library and fuel (the biofuel distiller is craftable in
    # Mineclonia). Required by the Super Cub.
    airutils = contentdb {
      file = "cc6062d99e"; # 0.97
      hash = "sha256-aK98dcDyhcMQh3LAqSh76R5fGqcD/XQuZP97rV5FgR4=";
    };

    # Flyable Super Cub plane. Its recipes are only registered when Minetest
    # Game's default mod is present and use MTG items, so drop that check
    # and use Mineclonia items (mese becomes redstone). Its break drops get
    # the same renaming.
    supercub = pkgs.applyPatches {
      name = "supercub";
      src = contentdb {
        file = "4cddc94cd5"; # 0.64a
        hash = "sha256-4HUlgUP07Vp0NxFvtvEAQauCPz+Pfcro7PdY4Gn6hh4=";
      };
      postPatch = ''
        for f in crafts.lua init.lua; do
          substituteInPlace $f \
            --replace-quiet '"wool:white"' '"mcl_wool:white"' \
            --replace-quiet "'wool:white'" "'mcl_wool:white'" \
            --replace-quiet '"farming:string"' '"mcl_mobitems:string"' \
            --replace-quiet '"default:steel_ingot"' '"mcl_core:iron_ingot"' \
            --replace-quiet "'default:steel_ingot'" "'mcl_core:iron_ingot'" \
            --replace-quiet '"default:diamondblock"' '"mcl_core:diamondblock"' \
            --replace-quiet "'default:diamond'" "'mcl_core:diamond'" \
            --replace-quiet '"default:mese_block"' '"mcl_redstone_torch:redstoneblock"' \
            --replace-quiet "'default:mese_crystal'" "'mcl_redstone:redstone'"
        done
        substituteInPlace crafts.lua \
          --replace-fail 'and minetest.get_modpath("default")' ""
        ! grep -nE "default:|'wool:|\"wool:|farming:" crafts.lua init.lua
      '';
    };

    # Entity API used by the motorboat.
    mobkit = contentdb {
      file = "269b82ebde"; # 2026-08-29
      hash = "sha256-KWhnwVA7f4oawiYxWoFFgtZxpnTXpZCQ8HpUl+x1yuc=";
    };

    # Motorboat. Written for Minetest Game only, so for Mineclonia:
    # - drop the hard default and biofuel deps (it also takes airutils'
    #   biofuel, and only uses default for its recipes);
    # - shim Minetest Game's player_api onto Mineclonia's mcl_player;
    # - register the recipes with Mineclonia items (mese becomes redstone).
    # Mineclonia's mcl_dye:<colour> names already work for painting it.
    motorboat = pkgs.applyPatches {
      name = "motorboat";
      src = contentdb {
        file = "35de2727d8"; # 0.43c
        hash = "sha256-x50/EgYyQlOE9XfYcfAR90JfbvunRl/cPq43K7KVKSg=";
      };
      postPatch = ''
        substituteInPlace mod.conf \
          --replace-fail "depends = mobkit,default,biofuel" \
            $'depends = mobkit\noptional_depends = mcl_player, airutils'
        sed -i '1i local player_api = rawget(_G, "player_api") or {player_attached = mcl_player.player_attached, registered_models = {}, set_animation = function(p, a, s) mcl_player.player_set_animation(p, a, s) end}' init.lua
        substituteInPlace init.lua \
          --replace-fail 'if core.get_modpath("default") then' 'do' \
          --replace-fail '"default:mese_block"' '"mcl_redstone_torch:redstoneblock"' \
          --replace-fail '"default:diamond"' '"mcl_core:diamond"' \
          --replace-fail '"default:glass"' '"mcl_core:glass"' \
          --replace-fail '"default_water.png^' '"default_water_source_animated.png^[verticalframe:16:0^' \
          --replace-fail '"default:steel_ingot"' '"mcl_core:iron_ingot"'
      '';
    };

    # Leads for moving and tethering animals.
    leads = contentdb {
      file = "4a97f0585a"; # 0.4.0
      hash = "sha256-H+dlg1ZAUSy6MWyjF3uhZsShu4Go6qzNiruetnyJ4Ms=";
    };

    # Steampunk airship; has its own Mineclonia recipes.
    steampunk_blimp = contentdb {
      file = "62aefece71"; # 0.60
      hash = "sha256-XgV8hMhVLr56TtUimBv4NQUL+d3RKXLyinXueaSbzcc=";
    };

    # Helicopter. Same treatment as the Super Cub; Mineclonia has no tin, so
    # copper stands in for it.
    heli = pkgs.applyPatches {
      name = "heli";
      src = contentdb {
        file = "3b4262a239"; # 0.15a
        hash = "sha256-xB66/0f3SMI+PBVUZ1XecPueAt6PnlcoF2/svaaufrI=";
      };
      postPatch = ''
        for f in crafts.lua init.lua; do
          substituteInPlace $f \
            --replace-quiet '"default:tin_ingot"' '"mcl_copper:copper_ingot"' \
            --replace-quiet "'default:tin_ingot'" "'mcl_copper:copper_ingot'" \
            --replace-quiet '"default:tinblock"' '"mcl_copper:block"' \
            --replace-quiet '"default:steel_ingot"' '"mcl_core:iron_ingot"' \
            --replace-quiet '"default:glass"' '"mcl_core:glass"' \
            --replace-quiet '"default:diamondblock"' '"mcl_core:diamondblock"' \
            --replace-quiet "'default:diamond'" "'mcl_core:diamond'" \
            --replace-quiet '"default:mese_block"' '"mcl_redstone_torch:redstoneblock"' \
            --replace-quiet "'default:mese_crystal'" "'mcl_redstone:redstone'"
        done
        substituteInPlace crafts.lua \
          --replace-fail 'and minetest.get_modpath("default")' ""
        ! grep -nE "default:" crafts.lua init.lua
      '';
    };

    # Cars, motorcycles and scooters (a modpack). Driving works in Mineclonia,
    # but every recipe is behind a check for Minetest Game's default mod, so
    # drop those and use Mineclonia items (copper for tin, redstone for mese).
    automobiles_pck = pkgs.applyPatches {
      name = "automobiles_pck";
      src = contentdb {
        file = "fc944c216f"; # 0.74
        hash = "sha256-RXnbrJ59nCWxAq+1dGzq9Uar5BgClJnuUIOEo014Up4=";
      };
      postPatch = ''
        files=$(grep -rl --include='*.lua' 'get_modpath("default")' .)
        sed -i \
          -e 's/if minetest\.get_modpath("default") then/if true then/' \
          -e 's/"default:steel_ingot"/"mcl_core:iron_ingot"/g' \
          -e 's/"default:steelblock"/"mcl_core:ironblock"/g' \
          -e 's/"default:tin_ingot"/"mcl_copper:copper_ingot"/g' \
          -e 's/"default:glass"/"mcl_core:glass"/g' \
          -e 's/"default:stick"/"mcl_core:stick"/g' \
          -e 's/"default:mese_block"/"mcl_redstone_torch:redstoneblock"/g' \
          -e 's/"default:mese"/"mcl_redstone_torch:redstoneblock"/g' \
          -e 's/"wool:\([a-z]*\)"/"mcl_wool:\1"/g' \
          $files
        ! grep -nE '"default:|"wool:|get_modpath\("default"\)' $files
      '';
    };

    # On-demand item transport, networked storage and autocrafting.
    logistica = contentdb {
      file = "545ef8d544"; # 2.0.13
      hash = "sha256-sZgSHcvwXlz0ab3P3Z4xLYQv2tQ1t4F5PnyzDI6tqLo=";
    };

    # Electricity and machines, in the style of Technic/IndustrialCraft 2.
    industrialtest = contentdb {
      file = "2bacabeafd"; # 2.2.0
      hash = "sha256-e5eeAsTAK33Gp90FqtZKgQjnEPxs5qNnvw3Xh5+OFnM=";
    };

    # Player cannons, pipes and tractor beams.
    traverse = contentdb {
      file = "4a2f15ebb0"; # 3.1
      hash = "sha256-h4pXS21i5zLdXngHcKLJ4LuEC3xjjYdWoCDAJj0svpE=";
    };

    # Machines, power and fluids (a modpack), with a Mineclonia compat layer.
    # Needs fluid_lib's tanks and transfer mods.
    elepower = contentdb {
      file = "50ccd715c1"; # Beta 3.10
      hash = "sha256-WOtwZpXAXIZg7UC2+7TzcxHlXM3ilTioeLrHRBM6+EA=";
    };
    fluid_lib = contentdb {
      file = "379b054861"; # 2026-06-08
      hash = "sha256-IGNmCEQfszguv1etvpFkII3y/ljv6NAtm4LCgArCer4=";
    };

    # Trains (a modpack). Its recipes use Minetest Game items, which the
    # compatibility patch re-registers with Mineclonia ones. advtrains itself
    # only has track, signals and automation; dlxtrains adds the trains.
    advtrains = contentdb {
      file = "a285f8b36a"; # v2.10.0
      hash = "sha256-1RQTF/Xx2/dQTAtQ38hPTXAIdbAxPeML8JsZozS9rak=";
    };
    advtrains_crafting_compatibility_patch = contentdb {
      file = "32f5d77376"; # 0.4.0
      hash = "sha256-yub1jp54PrPxgAtNZbcwAJHESd40dMN5hfVag84HKKY=";
    };
    dlxtrains = contentdb {
      file = "b0c6451657"; # 1.20.0
      hash = "sha256-KJm0vKR53GjWL2+JKM2m6sRpSoYoJ7odAxokP1DfW+4=";
    };
  };

  # Mods inside a game's mods/ directory are always enabled, so bundling them
  # avoids managing load_mod_* lines in the world's world.mt.
  mineclonia-modded = pkgs.runCommand "mineclonia-modded" {} ''
    cp -r ${mineclonia} $out
    chmod u+w $out/mods
    ${pkgs.lib.concatLines (pkgs.lib.mapAttrsToList (name: mod: "ln -s ${mod} $out/mods/${name}") mods)}
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
      # Admin: this player gets every privilege except the "cheaty" ones
      # (give, fly, fast, noclip, teleport, settime, ...), which Luanti
      # withholds by default. The admin has "privs", so grant those in game
      # with e.g. /grantme give; grants persist in auth.sqlite. Luanti names are
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
