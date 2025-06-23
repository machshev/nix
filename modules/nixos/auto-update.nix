{
  config,
  lib,
  ...
}:
with lib; {
  options = {
    machshev.autoupdate.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Automatically update NixOS";
    };
    machshev.autoupdate.flakePath = mkOption {
      type = types.str;
      description = "Path to the flake to use";
      default = "github:machshev/mynix";
    };
  };

  config = mkIf config.machshev.autoupdate.enable {
    system.autoUpgrade = {
      enable = true;
      flake = config.machshev.autoupdate.flakePath;
      flags = [
        "--update-input"
        "nixpkgs"
        "--no-write-lock-file"
        "-L" # print build logs
      ];
      dates = "02:00";
      randomizedDelaySec = "45min";
    };
  };
}
