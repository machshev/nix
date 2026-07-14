{
  inputs,
  pkgs,
  ...
}: let
  stateDir = "/var/lib/haqor-sync";
  tokenPath = "${stateDir}/token";
in {
  networking.firewall.allowedTCPPorts = [8788];

  users.groups.haqor-sync = {};
  users.users.haqor-sync = {
    group = "haqor-sync";
    isSystemUser = true;
  };

  systemd.services.haqor-sync = {
    description = "Haqor learner progress sync server";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    wants = ["network-online.target"];

    serviceConfig = {
      User = "haqor-sync";
      Group = "haqor-sync";
      StateDirectory = "haqor-sync";
      StateDirectoryMode = "0700";
      UMask = "0077";
      ExecStartPre = pkgs.writeShellScript "haqor-sync-init" ''
        if [ ! -s "${tokenPath}" ]; then
          ${pkgs.openssl}/bin/openssl rand -hex 32 > "${tokenPath}"
        fi
      '';
      ExecStart = pkgs.writeShellScript "haqor-sync" ''
        exec ${inputs.haqor-core.packages.${pkgs.stdenv.hostPlatform.system}.haqor-sync-server}/bin/haqor-sync-server \
          --bind 0.0.0.0:8788 \
          --progress "${stateDir}/progress.db" \
          --token "$(<"${tokenPath}")"
      '';
      Restart = "on-failure";
      RestartSec = "5s";
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
    };
  };
}
