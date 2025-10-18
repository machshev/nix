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
  };

  config = lib.mkMerge [
    (mkIf config.machshev.games.enable {
      environment.systemPackages = with pkgs; [
        lunar-client
      ];
    })

    (mkIf config.machshev.games.steam.enable {
      programs.steam = {
        enable = true;
      };

      environment.systemPackages = with pkgs; [
        steam-run
      ];

      nixpkgs.config.allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "steam"
          "steam-original"
          "steam-unwrapped"
          "steam-run"
        ];
    })
  ];
}
