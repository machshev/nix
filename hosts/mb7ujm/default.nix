{
  lib,
  modulesPath,
  pkgs,
  ...
}: let
  direwolf =
    (pkgs.direwolf.override {
      # This gateway uses GPIO directly, not hamlib rig control.
      hamlibSupport = false;
    }).overrideAttrs
    (old: {
      nativeBuildInputs = (old.nativeBuildInputs or []) ++ [pkgs.pkg-config];
      buildInputs = (old.buildInputs or []) ++ [pkgs.libgpiod];
    });

in {
  imports = [
    (modulesPath + "/installer/sd-card/sd-image-aarch64.nix")
  ];

  image.baseName = "nixos-mb7ujm";

  # The image grows its root partition to fill the SD card on first boot.
  sdImage = {
    compressImage = true;
    populateFirmwareCommands = lib.mkAfter ''
      # Keep the USB sound card at ALSA card 0 by disabling unused onboard
      # audio. The generic aarch64 SD image module copies this file from the
      # read-only Nix store, preserving its non-writable mode.
      chmod u+w firmware/config.txt
      echo "dtparam=audio=off" >> firmware/config.txt
    '';
  };

  nixpkgs.config.allowUnfree = true;

  networking = {
    hostName = "mb7ujm";
    networkmanager = {
      enable = true;
      wifi.powersave = false;
    };
    firewall.enable = true;
  };

  hardware = {
    # The generic SD image enables installer-style support for every machine.
    # This is a fixed Pi Zero 2 W image, so keep only its wireless firmware.
    enableAllHardware = lib.mkForce false;
    enableAllFirmware = false;
    enableRedistributableFirmware = false;
    firmware = [pkgs.raspberrypiWirelessFirmware];
    wirelessRegulatoryDatabase = true;
  };

  boot = {
    # 512 MiB is tight during activation and log compression.
    initrd.availableKernelModules = ["usbhid" "usb_storage"];
    kernelParams = ["cfg80211.ieee80211_regdom=GB"];
    kernelModules = ["brcmfmac" "dwc2" "snd-usb-audio"];
    supportedFilesystems = lib.mkForce ["ext4" "vfat"];
    tmp.cleanOnBoot = true;
    zfs.forceImportRoot = false;
  };
  zramSwap = {
    enable = true;
    memoryPercent = 100;
  };

  services = {
    openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
      };
    };

    journald.extraConfig = ''
      SystemMaxUse=64M
      RuntimeMaxUse=16M
    '';

    udev = {
      packages = [direwolf];
      extraRules = ''
        SUBSYSTEM=="gpio", KERNEL=="gpiochip*", GROUP="gpio", MODE="0660"
      '';
    };
  };

  users = {
    groups = {
      direwolf = {};
      gpio = {};
    };

    users = {
      jamesm = {
        isNormalUser = true;
        description = "James McCorrie";
        extraGroups = ["audio" "gpio" "networkmanager" "wheel"];
        openssh.authorizedKeys.keyFiles = [../../keys/jamesm.keys];
      };

      direwolf = {
        isSystemUser = true;
        group = "direwolf";
        extraGroups = ["audio" "gpio"];
      };
    };
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    alsa-utils
    direwolf
    libgpiod
  ];

  systemd.services.direwolf = {
    description = "Dire Wolf APRS iGate for MB7UJM";
    documentation = ["https://github.com/wb2osz/direwolf"];
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target"];
    after = [
      "network-online.target"
      "sound.target"
      "systemd-udev-settle.service"
    ];
    serviceConfig = {
      Type = "simple";
      User = "direwolf";
      Group = "direwolf";
      SupplementaryGroups = ["audio" "gpio"];
      ExecStart = "${lib.getExe direwolf} -t 0 -c ${./direwolf.conf}";
      Restart = "on-failure";
      RestartSec = "10s";
      StateDirectory = "direwolf";
      WorkingDirectory = "/var/lib/direwolf";

      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
    };
  };

  nix = {
    channel.enable = false;
    settings = {
      experimental-features = ["nix-command" "flakes"];
      trusted-users = ["root" "@wheel"];
    };
  };

  documentation.enable = false;
  programs.git.enable = true;

  system.stateVersion = "26.05";
}
