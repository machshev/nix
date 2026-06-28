{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options = {
    machshev.graphics.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable graphics.";
    };

    machshev.graphics.intel = mkOption {
      type = types.bool;
      default = false;
      description = "Enable intel graphics.";
    };

    machshev.graphics.nvidia = mkOption {
      type = types.bool;
      default = false;
      description = "Enable nvidia graphics.";
    };
  };

  config = lib.mkMerge [
    (mkIf config.machshev.graphics.enable {
      hardware.graphics.enable = true;
      hardware.graphics.enable32Bit = true;
    })

    (mkIf config.machshev.graphics.intel {
      # Required because the intel GPU isn't supported well, does it work with the
      # latest?
      boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
      boot.kernelParams = [
        "i915.enable_psr=0"
      ];
    })

    (mkIf config.machshev.graphics.nvidia {
      # nvidia legacy drivers don't build on 6.10
      # boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_9;

      # environment.systemPackages = [ nvidia-offload ];
      services.xserver.videoDrivers = lib.mkDefault ["nvidia"];
      # hardware.graphics.extraPackages = with pkgs; [vaapiVdpau];

      nixpkgs.config.nvidia.acceptLicense = true;

      hardware.nvidia = {
        modesetting.enable = true;

        powerManagement.enable = false;
        powerManagement.finegrained = false;
        forceFullCompositionPipeline = true;

        open = false; # not supported for legacy drivers
        nvidiaSettings = true;

        package = config.boot.kernelPackages.nvidiaPackages.legacy_470;
      };

      # boot.blacklistedKernelModules = ["nouveau"];

      # modesetting.enable doesn't reliably add this in newer nixpkgs
      boot.kernelParams = [ "nvidia-drm.modeset=1" ];

      # GDM Wayland greeter fails with NVIDIA 470 — use X11 for the greeter only
      services.displayManager.gdm.settings.daemon.WaylandEnable = false;

      # Required for wlroots (Sway) to use the NVIDIA driver
      environment.sessionVariables = {
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        WLR_NO_HARDWARE_CURSORS = lib.mkForce "1";
        WLR_DRM_NO_ATOMIC = "1";
      };

      programs.sway.extraOptions = ["--unsupported-gpu"];
    })
  ];
}
