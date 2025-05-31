{inputs, ...}: {
  imports = [
    inputs.disko.nixosModules.disko
  ];

  disko.devices = {
    disk = {
      disk1 = {
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            EFI = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            zfs = {
              end = "-8G";
              content = {
                type = "zfs";
                pool = "pool";
              };
            };
            swap = {
              size = "100%";
              content = {
                type = "swap";
                randomEncryption = true;
              };
            };
          };
        };
      };
    };
    zpool = {
      pool = {
        type = "zpool";
        options = {
          ashift = "12";
          autotrim = "on";
        };
        mountpoint = null;
        rootFsOptions = {
          acltype = "posixacl";
          xattr = "sa";
          dnodesize = "auto";
          compression = "lz4";
          normalization = "formD";
          canmount = "off";
          mountpoint = "none";
          "com.sun:auto-snapshot" = "false";
        };

        datasets = {
          ROOT = {
            type = "zfs_fs";
            mountpoint = "/";
          };

          NIX = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options.mountpoint = "legacy";
          };

          VAR = {
            type = "zfs_fs";
            mountpoint = "/var";
            options.mountpoint = "legacy";
          };

          USER = {
            type = "zfs_fs";
            mountpoint = "/home";
            options = {
              mountpoint = "legacy";
              "com.sun:auto-snapshot" = "true";
            };
          };

          DISK = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
        };
      };
    };
  };

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
    autoSnapshot = {
      enable = true;
      daily = 31;
      weekly = 8;
    };
  };
}
