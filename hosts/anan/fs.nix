{...}: {
  # This VPS has 1GB of RAM, which is too little for the kexec image that
  # nixos-anywhere boots, and the provider offers neither a resize nor a NixOS
  # ISO. NixOS was therefore installed in place over the provider's Ubuntu
  # image, which means the partition layout is inherited rather than declared
  # with disko: the filesystems below already existed and are matched by UUID.
  machshev.boot = false;

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/1af52c72-24ee-46b6-8e75-be5adce5e9d3";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/1d82ba79-209d-4da4-9534-77487ea14a54";
    fsType = "ext4";
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/DD42-7FC0";
    fsType = "vfat";
    options = ["umask=0077"];
  };

  # A swap partition would need repartitioning, so swap is a file on the root
  # filesystem. Without it 1GB is not enough to rebuild the system on the host.
  swapDevices = [
    {
      device = "/swapfile";
      size = 2048;
    }
  ];

  # GRUB registers itself in the firmware's NVRAM. Installing only to the
  # removable fallback path (\EFI\BOOT\BOOTX64.EFI) instead is not enough on this
  # VPS: its firmware does not reliably try that path, so an install with no
  # NVRAM entry leaves the machine sitting in the UEFI shell. The two options are
  # mutually exclusive in NixOS, so the NVRAM entry is the one to keep.
  #
  # The EFI system partition is only 105MB, so kernels live on the separate
  # 989MB /boot and the number of generations offered is capped.
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    configurationLimit = 10;
  };
  boot.loader.efi = {
    efiSysMountPoint = "/boot/efi";
    canTouchEfiVariables = true;
  };
}
