{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options = {
    machshev.hostName = mkOption {
      type = types.str;
      description = "Machine host name.";
    };
    machshev.networkWait = mkOption {
      type = types.bool;
      default = false;
      description = "Systemd wait-online check enable.";
    };
    machshev.wireshark = mkOption {
      type = types.bool;
      default = false;
      description = "Wireshark enable.";
    };
  };

  config = lib.mkMerge [
    {
      networking.hostName = config.machshev.hostName;

      environment.etc."machine-id".text = config.machshev.machineID;
      networking.hostId = builtins.substring 0 8 config.machshev.machineID;

      systemd.network.wait-online.enable = config.machshev.networkWait;
      systemd.network.wait-online.anyInterface = true;

      services.resolved.enable = true;
      networking.useNetworkd = true;
      networking.nftables.enable = true;
      networking.nameservers = ["1.1.1.1" "8.8.8.8"];

      # Enable the OpenSSH daemon.
      services.openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
        };
        openFirewall = true;
      };

      boot.kernel.sysctl = {
        "net.core.default_qdisc" = "fq";
        "net.ipv4.tcp_congestion_control" = "bbr";
      };
    }

    (mkIf config.machshev.server {
      networking.networkmanager.enable = true;
      environment.systemPackages = with pkgs; [
        networkmanager
        networkmanagerapplet
      ];
    })

    (mkIf config.machshev.wireshark {
      programs.wireshark = {
        enable = true;
        dumpcap.enable = true;
        usbmon.enable = true;
        package = pkgs.wireshark;
      };
    })
  ];
}
