{inputs, ...}: {
  imports = [
    inputs.disko.nixosModules.disko
  ];

  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
  };

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
