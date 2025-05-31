{
  config,
  lib,
  ...
}:
with lib; {
  options = {
    machshev.boot = mkOption {
      type = types.bool;
      default = true;
      description = "Enable boot options.";
    };

    machshev.closedFirmwareUpdates = mkOption {
      type = types.bool;
      default = false;
      description = "Enable updating unfree firmware.";
    };
  };

  config = mkIf config.machshev.boot {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.efiSysMountPoint = "/boot";
    boot.loader.efi.canTouchEfiVariables = true;
    boot.initrd.systemd.enable = true;

    # Firmware update service
    services.fwupd.enable = true;

    # Open drivers
    hardware.enableRedistributableFirmware = true;

    # Closed drivers
    nixpkgs.config.allowUnfree = config.machshev.closedFirmwareUpdates;
    hardware.enableAllFirmware = config.machshev.closedFirmwareUpdates;
  };
}
