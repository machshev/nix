#!/usr/bin/env bash
# Enroll a host into the mccorrie nebula overlay.
#
#   ./scripts/nebula-enroll.sh <host> [ssh-target]
#
# Signs a certificate for <host> with the nebula CA, then writes it into
# hosts/<host>/nebula.yaml encrypted with sops. The host must be reachable over
# SSH so its host key can be read: sops-nix decrypts on the target using the age
# key derived from /etc/ssh/ssh_host_ed25519_key, so that key has to be a
# recipient. If the host has no rule in .sops.yaml yet, one is added.
#
# Requires the nebula CA private key, which lives sops-encrypted in
# secrets/nebula/ca.key.enc and is decrypted here with a YubiKey. The plaintext
# CA key is never written to disk.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"

HOST="${1:?usage: nebula-enroll.sh <host> [ssh-target]}"
TARGET="${2:-$HOST}"

# Address and groups must agree with the node table in modules/nixos/nebula.nix.
case "$HOST" in
anan) IP=10.42.0.1 GROUPS=servers ;;
qatan) IP=10.42.0.10 GROUPS=servers ;;
gadol) IP=10.42.0.11 GROUPS=workstations ;;
tzedef) IP=10.42.0.12 GROUPS=workstations ;;
tapuach) IP=10.42.0.13 GROUPS=workstations ;;
hadasa) IP=10.42.0.14 GROUPS=workstations ;;
avodah) IP=10.42.0.20 GROUPS=workstations ;;
*)
  echo "error: '$HOST' is not in the node table; add it to modules/nixos/nebula.nix first" >&2
  exit 1
  ;;
esac

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
chmod 700 "$TMP"

echo "==> reading SSH host key from $TARGET"
ssh-keyscan -T 10 -t ed25519 "$TARGET" 2>/dev/null | grep -v '^#' >"$TMP/hostkey.pub"
[ -s "$TMP/hostkey.pub" ] || {
  echo "error: could not read an ed25519 host key from $TARGET (is it up?)" >&2
  exit 1
}
AGE_KEY="$(ssh-to-age -i "$TMP/hostkey.pub")"
echo "    age recipient: $AGE_KEY"

# Add the host to .sops.yaml if it is not already a recipient somewhere.
if ! grep -q "$AGE_KEY" .sops.yaml; then
  echo "==> adding $HOST to .sops.yaml"
  # Anchor goes under server-keys; the rule goes ahead of the catch-all so it
  # is matched first (sops uses the first creation_rule that matches).
  awk -v host="$HOST" -v key="$AGE_KEY" '
    /^server-keys:/ { print; print "  - &" host " " key; next }
    /^creation_rules:/ {
      print
      print "  - path_regex: hosts/" host "/*"
      print "    key_groups:"
      print "      - age:"
      print "          - *david-yk1"
      print "          - *david-yk2"
      print "          - *" host
      print ""
      next
    }
    { print }
  ' .sops.yaml >"$TMP/sops.yaml"
  mv "$TMP/sops.yaml" .sops.yaml
else
  echo "==> $HOST already a recipient in .sops.yaml"
fi

echo "==> decrypting CA key (touch your YubiKey)"
sops --decrypt --input-type binary --output-type binary \
  secrets/nebula/ca.key.enc >"$TMP/ca.key"

echo "==> signing certificate for $HOST ($IP, groups=$GROUPS)"
nebula-cert sign \
  -ca-crt secrets/nebula/ca.crt \
  -ca-key "$TMP/ca.key" \
  -name "$HOST" \
  -ip "$IP/24" \
  -groups "$GROUPS" \
  -out-crt "$TMP/host.crt" \
  -out-key "$TMP/host.key"
rm -f "$TMP/ca.key"

{
  echo "nebula:"
  echo "    cert: |"
  sed 's/^/        /' "$TMP/host.crt"
  echo "    key: |"
  sed 's/^/        /' "$TMP/host.key"
} >"$TMP/nebula.yaml"

mkdir -p "hosts/$HOST"
echo "==> encrypting hosts/$HOST/nebula.yaml"
sops --encrypt --filename-override "hosts/$HOST/nebula.yaml" "$TMP/nebula.yaml" \
  >"hosts/$HOST/nebula.yaml"

echo "==> done. Set 'machshev.nebula.enable = true;' in hosts/$HOST/default.nix and deploy."
