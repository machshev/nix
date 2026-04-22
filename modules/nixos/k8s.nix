{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options = {
    machshev.localDevK8s = mkOption {
      type = types.bool;
      default = true;
      description = "Enable local development K8s cluster.";
    };
  };

  config = mkIf config.machshev.localDevK8s {
    # Create a stable virtual interface for k8s
    systemd.network.netdevs."10-k8s0" = {
      netdevConfig = {
        Kind = "dummy";
        Name = "k8s0";
      };
    };

    systemd.network.networks."10-k8s0" = {
      matchConfig.Name = "k8s0";
      address = ["10.100.0.1/32"];
      linkConfig.RequiredForOnline = "no";
    };

    services.rke2 = {
      enable = true;
      nodeIP = "10.100.0.1";
      extraFlags = ["--advertise-address=10.100.0.1"];
    };

    # Buildkit daemon using RKE2's containerd as the worker so images built
    # with buildctl land directly in the k8s.io namespace without a save/import step.
    environment.etc."buildkit/buildkitd.toml".text = ''
      [worker.containerd]
        address = "/run/k3s/containerd/containerd.sock"
        namespace = "k8s.io"
        enabled = true

      [worker.oci]
        enabled = false
    '';

    # Allow users in the buildkit group to talk to buildkitd without sudo.
    users.groups.buildkit = {};

    systemd.services.buildkitd = {
      description = "BuildKit daemon";
      after = ["network.target" "rke2-server.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStart = "${pkgs.buildkit}/bin/buildkitd --config /etc/buildkit/buildkitd.toml --group buildkit";
        RuntimeDirectory = "buildkit";
        RuntimeDirectoryMode = "0755";
        Restart = "on-failure";
      };
    };
  };
}
