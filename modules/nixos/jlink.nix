{
  config,
  pkgs,
  lib,
  ...
}:
with lib; {
  options = {
    machshev.jlink = mkOption {
      type = types.bool;
      default = false;
      description = "Enable JLink.";
    };
  };

  config = mkIf config.machshev.jlink {
    # Here because it needs to be installed as a system package at the moment
    # until I can work out how to install it via homemanager. Perhaps use a
    # devshell instead.
    environment.systemPackages = with pkgs; [
      segger-jlink
    ];

    nixpkgs.config = {
      permittedInsecurePackages = [
        "segger-jlink-qt4-796s"
        "segger-jlink-qt4-794l"
      ];
      segger-jlink.acceptLicense = true;
    };
  };
}
