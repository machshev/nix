{
  config,
  inputs,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: let
  # Players given op level 4, copied from the Paper server's ops.json.
  javaOps = ["Fresh360" "josephmccorrie" "JEMcCorrie"];
  # Bedrock gamertag -> XUID. Floodgate's UUIDs on Paper are
  # 00000000-0000-0000-<XUID as 16 hex digits>.
  bedrockOps = {
    Da99er = "2533274828134400";
    RockCloud678071 = "2535435978056163";
  };

  s = builtins.substring;
  fmtUuid = h: "${s 0 8 h}-${s 8 4 h}-${s 12 4 h}-${s 16 4 h}-${s 20 12 h}";

  # Pumpkin's offline-mode Java UUID is the first 16 bytes of
  # SHA-256(username) (offline_uuid in pumpkin/src/net/mod.rs), not vanilla's
  # MD5 scheme.
  javaUuid = name: fmtUuid (builtins.hashString "sha256" name);

  # Bedrock UUIDs are MD5("pocket-auth-1-xuid:<XUID>") with the version 3 and
  # RFC 4122 variant bits set (xuid_to_uuid in pumpkin-util/src/jwt/mod.rs).
  bedrockUuid = xuid: let
    h = builtins.hashString "md5" "pocket-auth-1-xuid:${xuid}";
    # Variant: top two bits of byte 8 become 10, i.e. its high nibble is
    # (n & 3) | 8.
    variant = {
      "0" = "8";
      "4" = "8";
      "8" = "8";
      "c" = "8";
      "1" = "9";
      "5" = "9";
      "9" = "9";
      "d" = "9";
      "2" = "a";
      "6" = "a";
      "a" = "a";
      "e" = "a";
      "3" = "b";
      "7" = "b";
      "b" = "b";
      "f" = "b";
    };
  in
    fmtUuid "${s 0 12 h}3${s 13 3 h}${variant.${s 16 1 h}}${s 17 15 h}";

  mkOp = name: uuid: {
    inherit name uuid;
    level = 4;
    bypasses_player_limit = false;
  };

  opsFile = (pkgs.formats.json {}).generate "ops.json" (
    map (name: mkOp name (javaUuid name)) javaOps
    ++ lib.mapAttrsToList (name: xuid: mkOp name (bedrockUuid xuid)) bedrockOps
  );
in {
  # Pumpkin: a Rust Minecraft server that speaks both the Java and Bedrock
  # protocols natively, so no Geyser/ViaVersion. Trialled alongside the Paper
  # server in ./minecraft.nix, so it's shifted one port up on both protocols.
  # The module is only in nixos-unstable for now; drop this import once it's
  # in the stable release.
  imports = ["${inputs.nixpkgs-unstable}/nixos/modules/services/games/pumpkin.nix"];

  services.pumpkin = {
    enable = true;
    package = pkgs-unstable.pumpkin;
    openFirewall = true;
    # Offline mode: logins aren't checked against Mojang/Xbox Live, so anyone
    # who can reach the ports can join under any username.
    settings = {
      default_difficulty = "Hard";
      white_list = false;
      # Pumpkin's own optimised chunk format, rather than vanilla Anvil. The
      # world can't then be opened by vanilla/Paper.
      world.chunk.type = "pump";
      pvp.enabled = false;
      networking = {
        java = {
          address = "0.0.0.0:25566";
          max_players = 6;
          motd = "NixOS Pumpkin server!";
          online_mode = false;
          authentication.enabled = false;
        };
        bedrock = {
          enabled = true;
          address = "0.0.0.0:19133";
          max_players = 6;
          motd = "NixOS Pumpkin server!";
          online_mode = false;
          authentication.enabled = false;
        };
        # Advertises to Java clients' LAN list by multicasting to
        # 224.0.2.60:4445. Outbound only, so no firewall change needed.
        lan_broadcast.enabled = true;
        # Defaults to 25565 (UDP), which would clash with Paper if it ever
        # enables query.
        query.address = "0.0.0.0:25566";
      };
    };
  };

  # The module has no ops option. Merge the declared ops into data/ops.json
  # on each start, keeping any added in-game with /op; declared entries win
  # on a UUID clash. Removing a name here doesn't deop them, use /deop.
  systemd.services.pumpkin.preStart = lib.mkAfter ''
    ops="${config.services.pumpkin.dataDir}/data/ops.json"
    mkdir -p "$(dirname "$ops")"
    if [ -e "$ops" ]; then
      ${lib.getExe pkgs.jq} -s '.[0] + .[1] | unique_by(.uuid)' ${opsFile} "$ops" > "$ops.new"
      mv "$ops.new" "$ops"
    else
      install -m600 ${opsFile} "$ops"
    fi
  '';
}
