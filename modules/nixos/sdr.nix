{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options = {
    machshev.sdr = mkOption {
      type = types.bool;
      default = true;
      description = "Enable sdr options.";
    };
  };

  config = mkIf config.machshev.sdr {
    hardware.rtl-sdr.enable = true;

    environment.systemPackages = with pkgs; [
      rtl-sdr
      sdrangel
      gqrx
    ];
  };
}
