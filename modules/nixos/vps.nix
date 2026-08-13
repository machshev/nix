{
  config,
  lib,
  ...
}:
with lib; {
  options = {
    machshev.vps = mkOption {
      type = types.bool;
      default = false;
      description = "Enable vps options.";
    };
  };

  config = mkIf config.machshev.vps {
    boot.tmp.cleanOnBoot = true;

    # A headless VPS has a single DHCP interface that systemd-networkd already
    # configures. NetworkManager comes in via machshev.server, adds nothing here
    # and would contend with networkd for the same link.
    networking.networkmanager.enable = lib.mkForce false;

    hardware.graphics.enable = lib.mkForce false;

    # Server is accessed via ssh key only, so there are no passwords set
    security.sudo.wheelNeedsPassword = false;

    # VPS so no firmware to update
    services.fwupd.enable = lib.mkForce false;
    hardware.enableRedistributableFirmware = lib.mkForce false;
    hardware.enableAllFirmware = lib.mkForce false;
  };
}
