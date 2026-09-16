{
  pkgs ? import (builtins.getFlake (toString ../..)).inputs.nixpkgs {
    system = builtins.currentSystem;
    config.allowUnfree = true;
  },
}:
let
  driver = pkgs.stdenv.mkDerivation {
    pname = "beamng-software-vulkan-driver";
    version = "1";
    src = ./software-icd.c;
    dontUnpack = true;
    buildInputs = [ pkgs.vulkan-headers ];
    buildPhase = ''
      $CC -shared -fPIC -Wall -Wextra -Werror "$src" -o software-icd.so -ldl -pthread
    '';
    installPhase = ''
      mkdir -p "$out/lib"
      cp software-icd.so "$out/lib/"
    '';
  };
  manifest = pkgs.writeText "beamng-software-vulkan.json" (builtins.toJSON {
    file_format_version = "1.0.0";
    ICD = {
      library_path = "${driver}/lib/software-icd.so";
      api_version = "1.4.0";
    };
  });
in
pkgs.writeShellApplication {
  name = "beamng-software-vulkan";
  text = ''
    game_dir="''${BEAMNG_GAME_DIR:-''${XDG_DATA_HOME:-$HOME/.local/share}/Steam/steamapps/common/BeamNG.drive}"
    if [[ ! -x "$game_dir/BinLinux/BeamNG.drive.x64" ]]; then
      echo "Set BEAMNG_GAME_DIR to your BeamNG.drive installation directory." >&2
      exit 1
    fi
    export VK_DRIVER_FILES=${manifest}
    export VK_ICD_FILENAMES=${manifest}
    export LP_NUM_THREADS="''${LP_NUM_THREADS:-4}"
    export SteamAppId=284160
    export SteamGameId=284160
    user_dir="''${BEAMNG_USER_DIR:-''${XDG_DATA_HOME:-$HOME/.local/share}/BeamNG-software-test}"
    cd "$game_dir"
    exec ${pkgs.steam-run}/bin/steam-run env \
      LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [ pkgs.nspr pkgs.nss pkgs.vulkan-loader ]}:''${LD_LIBRARY_PATH:-}" \
      "$game_dir/BinLinux/BeamNG.drive.x64" -userpath "$user_dir" "$@"
  '';
}
