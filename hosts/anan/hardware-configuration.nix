{
  lib,
  modulesPath,
  inputs,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.disko.nixosModules.disko
  ];

  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi"];
  boot.initrd.kernelModules = ["nvme"];

  disko.devices = {
    disk.vda = {
      device = "/dev/vda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          # vda15 — ESP (FAT32, label UEFI)
          vda15 = {
            size = "512M";
            type = "EF00"; # EFI System
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["umask=0077"];
              extraArgs = ["-n" "UEFI"];
            };
          };

          # vda1 — root (ext4, label cloudimg-rootfs, rest of disk)
          vda1 = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              extraArgs = ["-L" "cloudimg-rootfs"];
            };
          };
        };
      };
    };
  };

  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
