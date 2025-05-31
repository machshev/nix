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
  };

  config = {
    networking.hostName = config.machshev.hostName;

    environment.etc."machine-id".text = config.machshev.machineID;
    networking.hostId = builtins.substring 0 8 config.machshev.machineID;

    networking.networkmanager.enable = true;
    environment.systemPackages = with pkgs; [
      networkmanager
      networkmanagerapplet
    ];

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
  };
}
