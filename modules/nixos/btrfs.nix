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
    # noatime everywhere: the default relatime still writes an atime update on
    # the first read of a file each day, and on a CoW filesystem each of those
    # dirties a metadata block. A tool that walks a large tree (a build, an
    # indexer, a repo scan) therefore turns a pure read into thousands of
    # scattered metadata writes. Nothing here depends on atime.
    fileSystems = {
      "/".options = ["compress=zstd" "noatime"];
      "/home".options = ["compress=zstd" "noatime"];
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
