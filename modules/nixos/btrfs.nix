{
  config,
  lib,
  ...
}:
with lib; {
  options = {
    machshev.btrfs = mkOption {
      type = types.bool;
      default = false;
      description = "Use BTFRS.";
    };
  };

  config = mkIf config.machshev.btrfs {
    fileSystems = {
      "/".options = ["compress=zstd"];
      "/home".options = ["compress=zstd"];
      "/nix".options = ["compress=zstd" "noatime"];
      #"/swap".options = [ "noatime" ];
    };

    services.btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = ["/"];
    };
  };
}
