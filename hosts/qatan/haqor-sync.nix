{
  config,
  inputs,
  pkgs,
  ...
}: let
  stateDir = "/var/lib/haqor-sync";
  usersDir = "${stateDir}/users";
  tlsDir = "${stateDir}/tls";
  port = 8788;
  server = inputs.haqor-core.packages.${pkgs.stdenv.hostPlatform.system}.haqor-sync-server;

  # Before learners had their own directories the server kept one token and
  # progress database at the top of the state directory. They move to this
  # learner on first start, keeping the token so joined devices carry on.
  legacyLearner = "david";

  # Addresses put in join links, in the order apps try them: the overlay
  # first, so roaming devices sync from anywhere, then the home network. The
  # app checks the pinned certificate before sending a token, so an address
  # that belongs to some other machine on another network is refused safely.
  joinServers = [
    "https://${config.machshev.nebula.address}:${toString port}"
    "https://${config.machshev.hostName}.lan:${toString port}"
  ];

  # `haqor-sync-join <learner>` prints that learner's join link and QR code,
  # creating the learner with a fresh token if they are new.
  haqor-sync-join = pkgs.writeShellScriptBin "haqor-sync-join" ''
    set -eu
    if [ "$#" -ne 1 ]; then
      echo "usage: haqor-sync-join <learner>" >&2
      exit 2
    fi
    if [ "$(id -u)" -ne 0 ]; then
      exec sudo "$0" "$@"
    fi
    umask 077
    exec ${pkgs.util-linux}/bin/runuser -u haqor-sync -- \
      ${server}/bin/haqor-sync-server join "$1" \
        --users-dir ${usersDir} \
        --tls-dir ${tlsDir} \
        ${builtins.concatStringsSep " " (map (s: "--server ${s}") joinServers)}
  '';
in {
  networking.firewall.allowedTCPPorts = [port];

  environment.systemPackages = [haqor-sync-join];

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
      ExecStartPre = pkgs.writeShellScript "haqor-sync-migrate" ''
        set -eu
        cd ${stateDir}
        learner=${usersDir}/${legacyLearner}
        # Gather into a staging directory and rename it into place last, so an
        # interrupted move is resumed on the next start and a migrated learner
        # is never overwritten.
        if [ ! -e "$learner" ] && { [ -s token ] || [ -d "$learner.partial" ]; }; then
          mkdir -p "$learner.partial"
          for f in progress.db progress.db-wal progress.db-shm token; do
            if [ -e "$f" ]; then mv "$f" "$learner.partial/"; fi
          done
          mv "$learner.partial" "$learner"
          echo "Moved the single-learner sync state to $learner"
        fi
      '';
      # HTTPS only: a device still on plain-HTTP settings is told to rejoin
      # with a link from haqor-sync-join.
      ExecStart = pkgs.writeShellScript "haqor-sync" ''
        exec ${server}/bin/haqor-sync-server \
          --bind 0.0.0.0:${toString port} \
          --users-dir ${usersDir} \
          --tls-dir ${tlsDir}
      '';
      Restart = "on-failure";
      RestartSec = "5s";
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
    };
  };
}
