{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options = {
    machshev.games.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable games.";
    };

    machshev.games.steam.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable steam.";
    };

    machshev.games.midtownMadness2.enable = mkEnableOption "Midtown Madness 2 with Wine";
  };

  config = lib.mkMerge [
    (mkIf config.machshev.games.midtownMadness2.enable {
      environment.systemPackages = [pkgs.machshev.midtown-madness-2];
      hardware.graphics.enable = true;

      # Midtown Madness 2 uses DirectPlay 4 for multiplayer.
      networking.firewall = {
        allowedTCPPortRanges = [{from = 2300; to = 2400;}];
        allowedUDPPortRanges = [{from = 2300; to = 2400;}];
        allowedTCPPorts = [47624];
        allowedUDPPorts = [47624];
      };
    })

    (mkIf config.machshev.games.enable {
      # Enable the uinput kernel module (required to create virtual controllers)
      boot.kernelModules = ["uinput"];

      environment.systemPackages = with pkgs; [
        lunar-client
        zeroad
        supertux
        supertuxkart
        mindustry
      ];

      # Enable advanced drivers for Xbox-style controller profiles
      hardware.xpadneo.enable = true;
      hardware.uinput.enable = true;

      services.udev.packages = with pkgs; [
        game-devices-udev-rules
      ];

      networking.firewall.allowedUDPPorts = [
        2759 # superTuxKart
        20595 # 0ad
      ];

      networking.firewall.allowedTCPPorts = [
        6567 # Mindustry
      ];
    })

    (mkIf config.machshev.games.steam.enable {
      programs.steam = {
        enable = true;
      };

      environment.systemPackages = with pkgs; [
        steam-run
        gamemode
      ];
    })
  ];
}
