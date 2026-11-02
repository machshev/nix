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
      default = "github:machshev/nix";
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
        # Machines that are off at 02:00 catch up shortly after boot
        # (Persistent=true), so keep the upgrade from saturating every core
        # and pinning the fans while someone is using the machine.
        "--max-jobs"
        "1"
        "--cores"
        "2"
      ];
      dates = "02:00";
      randomizedDelaySec = "45min";
    };

    # Evaluation runs in this unit; builds run in nix-daemon and are limited
    # by the flags above.
    systemd.services.nixos-upgrade.serviceConfig = {
      Nice = 19;
      CPUSchedulingPolicy = "idle";
      IOSchedulingClass = "idle";
    };
  };
}
