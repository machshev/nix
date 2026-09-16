# SPDX-License-Identifier: MIT
{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  wineWow64Packages,
  writeShellApplication,
  makeDesktopItem,
  copyDesktopItems,
  coreutils,
  util-linux,
  cacert,
  cabextract,
  xwayland-run,
}: let
  homepage = "https://www.myabandonware.com/game/midtown-madness-2-a07";
  # Wine 11's built-in dpwsockx cannot host DirectPlay sessions. Use the
  # redistributable and component list used by Winetricks' directplay verb.
  directplay = stdenvNoCC.mkDerivation {
    pname = "midtown-madness-2-directplay";
    version = "2010-02";
    src = fetchurl {
      url = "https://files.holarse-linuxgaming.de/mirrors/microsoft/directx_feb2010_redist.exe";
      sha256 = "f6d191e89a963d7cca34f169d30f49eab99c1ed3bb92da73ec43617caaa1e93f";
    };
    nativeBuildInputs = [cabextract];
    dontUnpack = true;
    installPhase = ''
      runHook preInstall
      cabextract -L -F dxnt.cab "$src"
      mkdir -p "$out"
      for component in dplaysvr.exe dplayx.dll dpmodemx.dll dpnet.dll \
        dpnhpast.dll dpnhupnp.dll dpnsvr.exe dpwsockx.dll; do
        cabextract -L -F "$component" -d "$out" dxnt.cab
      done
      runHook postInstall
    '';
    meta.license = lib.licenses.unfree;
  };
  gameData = stdenvNoCC.mkDerivation {
    pname = "midtown-madness-2-data";
    version = "1.0";

    src = fetchurl {
      name = "Midtown-Madness-2_Win_EN_RIP-Version.zip";
      # Download links require a session established by visiting the game page.
      # The redirect's CDN URL contains a temporary token and must not be pinned.
      url = homepage;
      curlOptsList = ["--cookie-jar" "mm2-cookies"];
      postFetch = ''
        curl --fail --location --retry 3 \
          --cacert '${cacert}/etc/ssl/certs/ca-bundle.crt' \
          --cookie mm2-cookies --referer '${homepage}' \
          'https://www.myabandonware.com/download/lvej-midtown-madness-2' \
          --output "$out"
      '';
      hash = "sha256-nE+Qc3goBhs0gp6Sc5D4fsuWGXxI5KEybUntmWYlm3w=";
    };

    nativeBuildInputs = [unzip];
    sourceRoot = "Midtown Madness 2 RIP";
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r . "$out/"
      # Discard the uploader's profile and hardware detection results, retaining
      # the original amateur/pro race data in the city subdirectories.
      rm -f "$out/gfxconf.dat" "$out/players/players.dir" \
        "$out/players/player0.cfg" "$out/players/player0.sav" \
        "$out/players/london/player0.rec" "$out/players/sf/player0.rec"
      test -f "$out/midtown2.exe"
      test -f "$out/mm2core.ar"
      runHook postInstall
    '';

    meta = {
      inherit homepage;
      description = "Original Midtown Madness 2 game data";
      license = lib.licenses.unfree;
      platforms = ["x86_64-linux"];
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  };
  gameRunner = writeShellApplication {
    name = "midtown-madness-2-run-game";
    runtimeInputs = [wineWow64Packages.stable];
    text = ''
      desktop=$1
      shift
      status=0
      wine explorer "/desktop=$desktop" midtown2.exe "$@" || status=$?
      # Explorer may return before the game. Keep the dedicated X server alive
      # until all of this prefix's Wine processes have exited.
      wineserver -w
      exit "$status"
    '';
  };
  launcher = writeShellApplication {
    name = "midtown-madness-2";
    runtimeInputs = [coreutils util-linux wineWow64Packages.stable xwayland-run];
    text =
      builtins.replaceStrings
      ["@gameData@" "@gameRunner@" "@directplay@"]
      ["${gameData}" "${lib.getExe gameRunner}" "${directplay}"]
      (builtins.readFile ./launch.sh);
  };
in
  stdenvNoCC.mkDerivation {
    pname = "midtown-madness-2";
    version = "1.0";
    dontUnpack = true;
    nativeBuildInputs = [copyDesktopItems];
    desktopItems = [
      (makeDesktopItem {
        name = "midtown-madness-2";
        desktopName = "Midtown Madness 2";
        comment = "Drive through London and San Francisco";
        exec = "midtown-madness-2";
        icon = "applications-games";
        categories = ["Game" "SportsGame"];
      })
    ];
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/bin"
      ln -s '${launcher}/bin/midtown-madness-2' "$out/bin/midtown-madness-2"
      runHook postInstall
    '';
    passthru = {inherit gameData directplay;};
    meta = {
      inherit homepage;
      description = "Midtown Madness 2 with a dedicated Wine runtime";
      license = lib.licenses.unfree;
      platforms = ["x86_64-linux"];
      mainProgram = "midtown-madness-2";
    };
  }
