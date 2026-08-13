#!/usr/bin/env bash
# Install the mccorrie nebula lighthouse on anan, which runs the provider's
# stock Ubuntu rather than NixOS.
#
#   ./scripts/nebula-lighthouse-ubuntu.sh [ssh-target]
#
# anan is the one host in the fleet that is not Nix-managed. Converting it in
# place repeatedly produced a NixOS that booted but had no network, and the
# provider offers no serial console, no rescue image, no custom ISO and a console
# viewer that renders output but does not deliver keystrokes — so the fault could
# never be observed. The mesh needs a lighthouse with a public address far more
# than it needs this particular box to be NixOS. hosts/anan/ is kept as-is so the
# conversion can be revisited, but it is NOT deployed: do not run deploy-rs
# against anan while this script owns the machine.
#
# Everything here matches modules/nixos/nebula.nix so the lighthouse and the
# NixOS members agree: same CA, same overlay, same port, same nebula version.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"

TARGET="${1:-root@87.106.54.175}"
NEBULA_VERSION="v1.10.3" # keep in step with pkgs.nebula on the NixOS hosts
IP="10.42.0.1"
GROUPS="servers"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
chmod 700 "$TMP"

echo "==> decrypting CA key (touch your YubiKey)"
sops --decrypt --input-type binary --output-type binary \
  secrets/nebula/ca.key.enc >"$TMP/ca.key"

echo "==> signing certificate for anan ($IP)"
nebula-cert sign \
  -ca-crt secrets/nebula/ca.crt \
  -ca-key "$TMP/ca.key" \
  -name anan \
  -ip "$IP/24" \
  -groups "$GROUPS" \
  -out-crt "$TMP/host.crt" \
  -out-key "$TMP/host.key"
rm -f "$TMP/ca.key"

# am_lighthouse and am_relay are what the other nodes point at; the firewall is
# open in both directions because membership of the overlay is the trust
# boundary, exactly as in the NixOS module.
cat >"$TMP/config.yml" <<'CONFIG'
pki:
  ca: /etc/nebula/ca.crt
  cert: /etc/nebula/host.crt
  key: /etc/nebula/host.key

static_host_map: {}

lighthouse:
  am_lighthouse: true
  interval: 60
  hosts: []

listen:
  host: 0.0.0.0
  port: 4242

punchy:
  punch: true
  respond: true

relay:
  am_relay: true
  use_relays: false

tun:
  disabled: false
  dev: tun.mccorrie

firewall:
  outbound:
    - port: any
      proto: any
      host: any
  inbound:
    - port: any
      proto: any
      host: any
CONFIG

cat >"$TMP/nebula.service" <<'UNIT'
[Unit]
Description=Nebula overlay network (mccorrie)
Wants=basic.target network-online.target
After=basic.target network.target network-online.target

[Service]
Type=notify
NotifyAccess=main
ExecStart=/usr/local/bin/nebula -config /etc/nebula/config.yml
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=5
SyslogIdentifier=nebula

[Install]
WantedBy=multi-user.target
UNIT

echo "==> copying to $TARGET"
scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  secrets/nebula/ca.crt "$TMP/host.crt" "$TMP/host.key" \
  "$TMP/config.yml" "$TMP/nebula.service" "$TARGET:/tmp/"

echo "==> installing"
# shellcheck disable=SC2087
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$TARGET" bash -s <<EOF
set -euo pipefail
curl -fsSL -o /tmp/nebula.tar.gz \
  https://github.com/slackhq/nebula/releases/download/$NEBULA_VERSION/nebula-linux-amd64.tar.gz
tar -xzf /tmp/nebula.tar.gz -C /usr/local/bin nebula nebula-cert
chmod 0755 /usr/local/bin/nebula /usr/local/bin/nebula-cert

install -d -m 0700 /etc/nebula
install -m 0644 /tmp/ca.crt /etc/nebula/ca.crt
install -m 0644 /tmp/host.crt /etc/nebula/host.crt
install -m 0600 /tmp/host.key /etc/nebula/host.key
install -m 0644 /tmp/config.yml /etc/nebula/config.yml
install -m 0644 /tmp/nebula.service /etc/systemd/system/nebula.service
rm -f /tmp/ca.crt /tmp/host.crt /tmp/host.key /tmp/config.yml /tmp/nebula.service /tmp/nebula.tar.gz

# The lighthouse is only reachable if the handshake port is.
if command -v ufw >/dev/null && ufw status | grep -q "Status: active"; then
  ufw allow 4242/udp
fi

systemctl daemon-reload
systemctl enable --now nebula.service
sleep 3
systemctl --no-pager --lines=15 status nebula.service || true
ip -4 addr show tun.mccorrie || echo "WARNING: tun.mccorrie has no address"
EOF

echo "==> done. Lighthouse should be reachable at $IP over the overlay."
