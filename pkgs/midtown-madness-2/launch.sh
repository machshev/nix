set -euo pipefail

if [[ ${1:-} == --help ]]; then
  cat <<'HELP'
Usage: midtown-madness-2 [--windowed] [GAME_ARGUMENTS...]
       midtown-madness-2 --winecfg

Launch Midtown Madness 2, or configure its private Wine prefix.
On Wayland, the game is scaled to fill the screen using a dedicated Xwayland.
Use --windowed for a Wine virtual desktop window instead.
Set MIDTOWN_MADNESS_2_DESKTOP=WIDTHxHEIGHT to change the game display size
(default: 1920x1080). On Wayland, using the monitor-sized default avoids
scaling the game's fixed-resolution DirectDraw surface.
Saves and settings: ${XDG_DATA_HOME:-$HOME/.local/share}/midtown-madness-2
Override this location with MIDTOWN_MADNESS_2_HOME (an absolute path).
HELP
  exit 0
fi

windowed=false
if [[ ${1:-} == --windowed ]]; then
  windowed=true
  shift
fi

desktop_size=${MIDTOWN_MADNESS_2_DESKTOP:-1920x1080}
if [[ ! $desktop_size =~ ^[1-9][0-9]{2,3}x[1-9][0-9]{2,3}$ ]]; then
  echo 'Midtown Madness 2: desktop size must be WIDTHxHEIGHT, for example 1024x768.' >&2
  exit 1
fi

state_dir=${MIDTOWN_MADNESS_2_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/midtown-madness-2}
if [[ $state_dir != /* ]]; then
  echo 'Midtown Madness 2: the data directory must be an absolute path.' >&2
  exit 1
fi
mkdir -p "$state_dir"
# Hold the lock until Wine exits, including first-run setup.
exec 9>"$state_dir/.lock"
if ! flock -n 9; then
  echo 'Midtown Madness 2 is already running for this data directory.' >&2
  exit 1
fi

export WINEPREFIX="$state_dir/wine"
export WINEARCH=win64
export WINEDEBUG=${WINEDEBUG:--all}
# Avoid unnecessary installers and Wine-generated file associations/menu items.
export WINEDLLOVERRIDES="mscoree,mshtml=;winemenubuilder.exe=d;${WINEDLLOVERRIDES:-}"

if [[ ! -f $WINEPREFIX/.midtown-initialized ]]; then
  wineboot -u
  wineserver -w
  wine reg add 'HKCU\Software\Wine' /v Version /t REG_SZ /d winxp /f
  touch "$WINEPREFIX/.midtown-initialized"
fi

# Upgrade existing prefixes too. MM2 is 32-bit, so its native DirectPlay
# components belong in syswow64 in this WoW64 prefix.
directplay_source=@directplay@
if [[ ! -f $WINEPREFIX/.midtown-directplay-source ]] ||
  [[ $(cat "$WINEPREFIX/.midtown-directplay-source") != "$directplay_source" ]]; then
  cp "$directplay_source/"* "$WINEPREFIX/drive_c/windows/syswow64/"
  chmod u+w "$WINEPREFIX/drive_c/windows/syswow64/"{dplaysvr.exe,dplayx.dll,dpmodemx.dll,dpnet.dll,dpnhpast.dll,dpnhupnp.dll,dpnsvr.exe,dpwsockx.dll}
  for component in dplaysvr.exe dplayx dpmodemx dpnet dpnhpast dpnhupnp dpnsvr.exe dpwsockx; do
    wine reg add 'HKCU\Software\Wine\DllOverrides' /v "$component" /t REG_SZ /d native /f
  done
  for component in dplayx dpnet dpnhpast dpnhupnp; do
    wine 'C:\windows\syswow64\regsvr32.exe' /s "$component.dll"
  done
  wineserver -w
  printf '%s\n' "$directplay_source" > "$WINEPREFIX/.midtown-directplay-source"
fi

if [[ ${1:-} == --winecfg ]]; then
  winecfg
  wineserver -w
  exit 0
fi

# Copy atomically on first launch. The game writes profiles and configuration
# beside its executable, so it cannot run directly from the Nix store.
if [[ ! -d $state_dir/game ]]; then
  staging=$(mktemp -d "$state_dir/.game.XXXXXX")
  trap 'rm -rf -- "$staging"' EXIT
  cp -r --reflink=auto @gameData@/. "$staging/"
  chmod -R u+w "$staging"
  mv "$staging" "$state_dir/game"
  trap - EXIT
fi

cd "$state_dir/game"
if "$windowed"; then
  exec @gameRunner@ "MidtownMadness2,$desktop_size" "$@"
elif [[ -n ${WAYLAND_DISPLAY:-} ]]; then
  # Rootful Xwayland scales the entire game display to the monitor, including
  # the fixed-resolution menus. A fullscreen Wine desktop alone does not.
  # Force Wine onto this X server rather than its native Wayland driver.
  exec xwayland-run -geometry "$desktop_size" -fullscreen -- \
    env -u WAYLAND_DISPLAY @gameRunner@ root "$@"
else
  # On an X11 session, let Wine use native fullscreen mode switching.
  exec @gameRunner@ root "$@"
fi
