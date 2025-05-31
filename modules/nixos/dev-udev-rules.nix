{
  config,
  pkgs,
  lib,
  ...
}:
with lib; {
  options = {
    machshev.applyUdevRules = mkOption {
      type = types.bool;
      default = false;
      description = "Load a set of udev rules useful for hardware hacking.";
    };
  };

  config = mkIf config.machshev.applyUdevRules {
    services.udev.packages = [
      pkgs.machshev.dev-udev-rules
    ];
  };
}
