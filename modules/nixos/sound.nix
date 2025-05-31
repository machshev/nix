{
  config,
  lib,
  ...
}:
with lib; {
  options = {
    machshev.sound = mkOption {
      type = types.bool;
      default = true;
      description = "Enable sound";
    };
  };

  config = mkIf config.machshev.sound {
    # Bluetooth
    services.blueman.enable = true;
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;

    # Enable sound with pipewire.
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    services.pipewire.extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.allowed-rates" = [48000 44100 88200 96000 192000];
        "default.clock.quantum" = 2048;
        "default.clock.min-quantum" = 1024;
        "default.clock.max-quantum" = 4096;
      };
    };

    # services.pipewire.wireplumber.extraConfig."10-bluez" = {
    #   "monitor.bluez.properties" = {
    #     "bluez5.enable-sbc-xq" = true;
    #     "bluez5.enable-msbc" = true;
    #     "bluez5.enable-hw-volume" = true;
    #     "bluez5.roles" = [
    #       "hsp_hs"
    #       "hsp_ag"
    #       "hfp_hf"
    #       "hfp_ag"
    #     ];
    #   };
    # };
  };
}
