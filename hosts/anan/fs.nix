{inputs, ...}: {
  imports = [
    inputs.disko.nixosModules.disko
  ];

  machshev.boot = false;
  boot.loader.grub.enable = true;

  disko.devices = {
    disk.vda = {
      device = "/dev/vda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          biosgrub = {
            size = "1M";
            type = "EF02"; # BIOS boot partition for GRUB
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
