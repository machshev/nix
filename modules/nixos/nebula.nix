{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.machshev.nebula;

  # Single source of truth for the overlay. Every node derives its own address,
  # the static host map and the /etc/hosts entries from this table, so adding a
  # machine only means adding a row here plus its sops-encrypted cert.
  nodes = {
    anan = {
      ip = "10.42.0.1";
      groups = ["servers"];
      # Public VPS, so it is the lighthouse and the relay that lets roaming
      # nodes reach machines sitting behind the home NAT.
      lighthouse = true;
      publicAddress = "anan.mccorrie.com";
    };
    qatan = {
      ip = "10.42.0.10";
      groups = ["servers"];
    };
    gadol = {
      ip = "10.42.0.11";
      groups = ["workstations"];
    };
    tzedef = {
      ip = "10.42.0.12";
      groups = ["workstations"];
    };
    tapuach = {
      ip = "10.42.0.13";
      groups = ["workstations"];
    };
    hadasa = {
      ip = "10.42.0.14";
      groups = ["workstations"];
    };
    avodah = {
      ip = "10.42.0.20";
      groups = ["workstations"];
    };
  };

  lighthouses = filterAttrs (_: n: n.lighthouse or false) nodes;

  self =
    nodes.${
      config.machshev.hostName
    } or (throw ''
      machshev.nebula is enabled on '${config.machshev.hostName}' but that host has
      no entry in the node table in modules/nixos/nebula.nix.
    '');
in {
  options.machshev.nebula = {
    enable = mkEnableOption "the mccorrie nebula overlay network";

    network = mkOption {
      type = types.str;
      default = "mccorrie";
      description = "Nebula network name; names the service, config and tun device.";
    };

    domain = mkOption {
      type = types.str;
      default = "mesh";
      description = ''
        Suffix used for the /etc/hosts entries generated for every overlay node,
        e.g. qatan.mesh. Kept distinct from any real DNS zone so a name only ever
        resolves to the overlay.
      '';
    };

    port = mkOption {
      type = types.port;
      default = 4242;
      description = ''
        UDP listen port. A fixed port rather than an ephemeral one so that the
        firewall can be opened for it: nodes on the same LAN otherwise never
        establish a direct tunnel and relay through the lighthouse instead,
        which sends traffic between two machines in the same room across the
        internet and makes them unreachable to each other whenever it is down.
      '';
    };

    subnet = mkOption {
      type = types.str;
      default = "10.42.0.0/24";
      description = ''
        Overlay subnet, in CIDR form. Chosen to stay clear of the home LAN and
        of any other overlay a machine may already be attached to.
      '';
    };
  };

  config = mkIf cfg.enable {
    sops.secrets = {
      "nebula/cert" = {
        sopsFile = ../../hosts/${config.machshev.hostName}/nebula.yaml;
        owner = "nebula-${cfg.network}";
        restartUnits = ["nebula@${cfg.network}.service"];
      };
      "nebula/key" = {
        sopsFile = ../../hosts/${config.machshev.hostName}/nebula.yaml;
        owner = "nebula-${cfg.network}";
        restartUnits = ["nebula@${cfg.network}.service"];
      };
    };

    services.nebula.networks.${cfg.network} = {
      enable = true;

      ca = ../../secrets/nebula/ca.crt;
      cert = config.sops.secrets."nebula/cert".path;
      key = config.sops.secrets."nebula/key".path;

      isLighthouse = self.lighthouse or false;
      isRelay = self.lighthouse or false;

      # A lighthouse neither points at itself nor relays through itself.
      lighthouses = optionals (!(self.lighthouse or false)) (mapAttrsToList (_: n: n.ip) lighthouses);
      relays = optionals (!(self.lighthouse or false)) (mapAttrsToList (_: n: n.ip) lighthouses);

      staticHostMap = mapAttrs' (_: n: nameValuePair n.ip ["${n.publicAddress}:4242"]) lighthouses;

      listen.port = cfg.port;
      tun.device = "tun.${cfg.network}";

      # Every certificate is issued by our own CA and only ever handed to a
      # machine in this table, so membership of the overlay is the trust
      # boundary; no further partitioning inside it.
      firewall = {
        outbound = [
          {
            port = "any";
            proto = "any";
            host = "any";
          }
        ];
        inbound = [
          {
            port = "any";
            proto = "any";
            host = "any";
          }
        ];
      };

      settings = {
        punchy = {
          punch = true;
          # Keeps the NAT mapping alive so home machines stay reachable from
          # outside without waiting for a relayed handshake.
          respond = true;
        };
      };
    };

    # Reach any node as <name>.mesh regardless of what the LAN's DNS knows.
    networking.hosts =
      mapAttrs' (
        name: n: nameValuePair n.ip ["${name}.${cfg.domain}"]
      )
      nodes;

    # Trust the overlay the same way the LAN is trusted; per-host services still
    # decide what they expose, and nebula's own firewall gates entry.
    networking.firewall.trustedInterfaces = ["tun.${cfg.network}"];
  };
}
