#!/usr/bin/env bash
# Generate a complete nebula config for a device that is not managed by NixOS —
# a phone running the Mobile Nebula app, a tablet, a laptop belonging to someone
# else. The app imports a single YAML file, so the CA, certificate and private
# key are inlined into it rather than referenced as paths.
#
#   ./scripts/nebula-enroll-mobile.sh <name> <overlay-ip>
#
# e.g. ./scripts/nebula-enroll-mobile.sh phone 10.42.0.30
#
# Addresses are not tracked in modules/nixos/nebula.nix: that table exists to
# configure NixOS hosts, and these devices are not one. Pick an address in
# 10.42.0.0/24 outside the ranges the fleet uses (.1 lighthouse, .10-.19 servers,
# .20-.29 workstations) — .30 upwards is free.
#
# Requires the nebula CA key, which is sops-encrypted to the YubiKeys, so run
# this from a terminal where the PIN prompt can reach you.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"

NAME="${1:?usage: nebula-enroll-mobile.sh <name> <overlay-ip>   e.g. phone 10.42.0.30}"
IP="${2:?usage: nebula-enroll-mobile.sh <name> <overlay-ip>   e.g. phone 10.42.0.30}"

case "$IP" in
10.42.0.*) ;;
*)
  echo "error: '$IP' is not in the 10.42.0.0/24 overlay" >&2
  exit 1
  ;;
esac

LIGHTHOUSE_IP="10.42.0.1"
LIGHTHOUSE_ADDR="87.106.54.175:4242"

OUT="$REPO/nebula-mobile-$NAME"
mkdir -p "$OUT"
chmod 700 "$OUT"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
chmod 700 "$TMP"

echo "==> decrypting CA key (PIN + touch)"
sops --decrypt --input-type binary --output-type binary \
  secrets/nebula/ca.key.enc >"$TMP/ca.key"

echo "==> signing $NAME ($IP, groups=mobile)"
nebula-cert sign \
  -ca-crt secrets/nebula/ca.crt \
  -ca-key "$TMP/ca.key" \
  -name "$NAME" \
  -networks "$IP/24" \
  -groups mobile \
  -out-crt "$TMP/host.crt" \
  -out-key "$TMP/host.key"
rm -f "$TMP/ca.key"

CONFIG="$OUT/$NAME.yaml"

# listen.port is 0 so the device picks an ephemeral port: a roaming client must
# not assume it can bind a fixed one, and it never needs to be dialled directly.
{
  echo "# nebula config for $NAME ($IP) on the mccorrie overlay"
  echo "# Contains this device's PRIVATE KEY. Transfer it securely and delete"
  echo "# this file once imported."
  echo "pki:"
  echo "  ca: |"
  sed 's/^/    /' secrets/nebula/ca.crt
  echo "  cert: |"
  sed 's/^/    /' "$TMP/host.crt"
  echo "  key: |"
  sed 's/^/    /' "$TMP/host.key"
  cat <<CONF

static_host_map:
  "$LIGHTHOUSE_IP": ["$LIGHTHOUSE_ADDR"]

lighthouse:
  am_lighthouse: false
  interval: 60
  hosts:
    - "$LIGHTHOUSE_IP"

listen:
  host: 0.0.0.0
  port: 0

punchy:
  punch: true
  respond: true

relay:
  am_relay: false
  use_relays: true
  relays:
    - "$LIGHTHOUSE_IP"

tun:
  disabled: false
  dev: nebula1
  mtu: 1300

firewall:
  outbound:
    - port: any
      proto: any
      host: any
  inbound:
    - port: any
      proto: any
      host: any
CONF
} >"$CONFIG"
chmod 600 "$CONFIG"

cat <<INFO

==> wrote $CONFIG

    Import it in the Mobile Nebula app: + -> Import from file, and pick this
    YAML. The certificate is valid until the CA expires.

    It embeds the device's private key, so send it over something private —
    AirDrop, a USB cable, or a password manager's secure note. Avoid email and
    chat apps. Delete it once the phone has imported it:

      shred -u $CONFIG && rmdir $OUT

    The phone reaches the fleet by overlay address (qatan is $LIGHTHOUSE_IP's
    neighbour at 10.42.0.10, and so on); it does not get the .mesh names, which
    are generated only for NixOS hosts.
INFO
