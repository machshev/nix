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
  #
  # Note: "dtparam="/"dtoverlay=" lines in config.txt have no effect here. The
  # extlinux config points U-Boot at FDTDIR in the Nix store, so the kernel is
  # handed the unmodified mainline DTB and the firmware's patched copy is
  # discarded. Device tree changes go through hardware.deviceTree below.
  sdImage.compressImage = true;

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

    deviceTree = {
      enable = true;

      # This is a fixed Pi Zero 2 W image, so ship only its device tree
      # instead of every board the kernel knows about. Keeps /boot to a few
      # kilobytes rather than 118 MiB and keeps the overlay step cheap.
      filter = "bcm2837-rpi-zero-2-w.dtb";

      overlays = [
        {
          # The Zero 2 W's data port is wired for OTG, so the controller only
          # comes up as a host when the cable grounds the ID pin. A plain
          # micro-USB-to-A adapter does not, and the sound card never
          # enumerates. Pin the controller to host mode instead.
          name = "dwc2-host-mode";
          dtsText = ''
            /dts-v1/;
            /plugin/;

            / {
              compatible = "brcm,bcm2837";

              fragment@0 {
                target-path = "/soc/usb@7e980000";
                __overlay__ {
                  dr_mode = "host";
                };
              };
            };
          '';
        }
      ];
    };
  };

  boot = {
    # 512 MiB is tight during activation and log compression.
    initrd.availableKernelModules = ["usbhid" "usb_storage"];
    kernelParams = ["cfg80211.ieee80211_regdom=GB"];
    kernelModules = ["brcmfmac" "dwc2" "snd-usb-audio"];

    # Onboard analogue audio is unused and would otherwise claim card 0.
    blacklistedKernelModules = ["snd_bcm2835"];
    extraModprobeConfig = ''
      # Reserve ALSA slot 0 for the USB sound card. Without this, vc4's HDMI
      # audio claims card 0 first and the dongle lands on an unpredictable
      # index. A plain "index=0" is not enough: it loses the race rather than
      # winning it, because the slot is already taken by the time USB probes.
      options snd slots=snd-usb-audio
    '';
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

  # The C-Media dongle powers up with automatic gain control enabled, which
  # pumps the gain between packets and skews the 1200-baud AFSK tone ratio the
  # demodulator depends on. Nothing persists ALSA mixer state on this host, so
  # set a fixed capture gain explicitly before Dire Wolf opens the device.
  systemd.services.direwolf-mixer = {
    description = "Fixed capture gain for the MB7UJM sound card";
    before = ["direwolf.service"];
    after = ["sound.target"];
    wantedBy = ["direwolf.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = let
        amixer = "${pkgs.alsa-utils}/bin/amixer -c 0";
      in
        pkgs.writeShellScript "direwolf-mixer" ''
          set -eu
          ${amixer} sset 'Auto Gain Control' off
          ${amixer} sset 'Mic' 35% cap

          # Transmit level into the radio. PROVISIONAL: no transmission from
          # this station has yet been received by anyone, so this value is
          # unvalidated -- it is recorded only so a reboot does not silently
          # restore the 73% default. Set properly once the radio side is
          # sorted and a beacon is actually heard.
          ${amixer} sset 'Speaker' 46%
        '';
    };
  };

  systemd.services.direwolf = {
    description = "Dire Wolf APRS iGate for MB7UJM";
    documentation = ["https://github.com/wb2osz/direwolf"];
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target"];
    after = [
      "network-online.target"
      "sound.target"
      "systemd-udev-settle.service"
      "direwolf-mixer.service"
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
