#!/usr/bin/env bash
set -euo pipefail

plugins="$MINECRAFT_DATA_DIR/plugins"
staging=$(mktemp -d)
restart_needed=false
installing=false

cleanup() {
  result=$?
  trap - EXIT
  if $installing; then
    echo "Installation failed; restoring previous plugin JARs" >&2
    rm -f "$plugins/Geyser-Spigot.jar" "$plugins/floodgate-spigot.jar" "$plugins"/ViaVersion-*.jar
    cp -p "$staging/backup/"*.jar "$plugins/" 2>/dev/null || true
  fi
  if $restart_needed; then
    systemctl start minecraft-server.service || result=1
  fi
  rm -rf "$staging"
  exit "$result"
}
trap cleanup EXIT

download() {
  curl --fail --location --silent --show-error --retry 3 \
    --connect-timeout 30 --max-time 180 "$1" -o "$2"
  unzip -tq "$2" >/dev/null
  # A valid ZIP alone could be an error artifact or the wrong platform.
  unzip -p "$2" plugin.yml >/dev/null
}

via_version=$(curl --fail --location --silent --show-error --retry 3 \
  --connect-timeout 30 --max-time 180 \
  https://hangar.papermc.io/api/v1/projects/ViaVersion/latest)
if [[ ! "$via_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9.-]+)?$ ]]; then
  echo "Invalid ViaVersion release: $via_version" >&2
  exit 1
fi
download "https://hangar.papermc.io/api/v1/projects/ViaVersion/versions/$via_version/PAPER/download" \
  "$staging/ViaVersion-$via_version.jar"
download https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot \
  "$staging/floodgate-spigot.jar"
# Follow the latest build of the official Java 26.3 support preview.
# https://github.com/GeyserMC/Geyser/pull/6712
download https://download.geysermc.org/v2/projects/geyserpreview/versions/pr.6712/builds/latest/downloads/spigot \
  "$staging/Geyser-Spigot.jar"

changed=false
for jar in "$staging/"*.jar; do
  if ! cmp -s "$jar" "$plugins/$(basename "$jar")"; then
    changed=true
  fi
done
shopt -s nullglob
for jar in "$plugins"/ViaVersion-*.jar; do
  if [[ "$(basename "$jar")" != "ViaVersion-$via_version.jar" ]]; then
    changed=true
  fi
done
if ! $changed; then
  echo "Minecraft plugins are already up to date"
  exit 0
fi

# Keep plugin directories, configuration, keys, and unrelated JARs intact.
install -d -o minecraft -g minecraft -m 0755 "$plugins"
mkdir -p "$staging/backup"
for jar in "$plugins/Geyser-Spigot.jar" "$plugins/floodgate-spigot.jar" "$plugins"/ViaVersion-*.jar; do
  if [[ -f "$jar" ]]; then
    cp -p "$jar" "$staging/backup/"
  fi
done

# Leave an intentionally stopped server stopped.
if systemctl is-active --quiet minecraft-server.service; then
  restart_needed=true
  systemctl stop minecraft-server.service
fi
installing=true
rm -f "$plugins"/ViaVersion-*.jar
for jar in "$staging/"*.jar; do
  install -o minecraft -g minecraft -m 0644 "$jar" "$plugins/$(basename "$jar")"
done
installing=false
echo "Updated Geyser, Floodgate and ViaVersion ($via_version)"
