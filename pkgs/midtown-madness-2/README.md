# Midtown Madness 2

Runs the English RIP ZIP from [My Abandonware](https://www.myabandonware.com/game/midtown-madness-2-a07)
with the flake's pinned Wine 11 WoW64 runtime on **x86_64 Linux**.
The archive is downloaded automatically and verified with SHA-256. Wine uses
its built-in DirectDraw/Direct3D support; Vulkan is not required.

From the repository root:

```sh
nix run .#midtown-madness-2
```

Or install it in a NixOS host configuration, then rebuild that host:

```nix
machshev.games.midtownMadness2.enable = true;
```

This adds **Midtown Madness 2** to the applications menu and opens the DirectPlay
multiplayer ports (TCP and UDP 2300–2400 and 47624). The game option works
independently of the general games setting. It is enabled on gadol, hadasa,
tapuach and tzedef, where `machshev.games.enable` is currently set. The package
is proprietary (`unfree`); the flake's
package set permits this specific game and its data.

## TCP/IP multiplayer

The launcher installs Microsoft's 32-bit DirectPlay components from the February
2010 DirectX redistributable into the game's private Wine prefix. Wine 11's
built-in TCP/IP provider cannot create a hosted session (`DPERR_UNSUPPORTED`).
The redistributable is checked against the SHA-256 used by
[Winetricks](https://github.com/Winetricks/winetricks/blob/master/src/winetricks).
Existing prefixes receive the components on their next launch; player profiles
are preserved.

On one computer, select **Multiplayer → TCP/IP → Host** and create a session.
Leave it in the multiplayer lobby. On the other, join using the host's LAN IPv4
address: `10.140.1.4` for tzedef or `10.140.1.1` for gadol on the home network.
Both computers must have the DirectPlay update and the game's firewall ports
open. Internet/overlay play has not been verified.

## Local setup

First launch creates a private Wine prefix and a writable copy of the game in
`${XDG_DATA_HOME:-$HOME/.local/share}/midtown-madness-2`. Allow a little extra
time for Wine setup. Create a player when the game starts, then try **Cruise**
for free driving around either city.

- `game/players/` contains player profiles and progress.
- `game/` also contains settings, game data and the original `Booklet.pdf` manual.
- `wine/` is the dedicated Wine prefix; your normal `~/.wine` is not used.

Back up this directory to preserve saves. Rebuilds leave the writable game
copy alone, including any mods you add. If a future package updates the game
data, back up your saves and move `game/` aside to get a fresh copy on launch.
Set `MIDTOWN_MADNESS_2_HOME` to a different absolute directory to create a
separate installation (for example, a separate set of profiles for a child).

On **Wayland**, the launcher starts a dedicated **fullscreen Xwayland** server.
It scales the game image, including the low-resolution menus, to fill the
monitor. This fixes the small image in the top-left corner without requiring
Vulkan or a system configuration change. On X11, Wine uses native fullscreen.
Existing profiles and game settings are preserved.

For the previous Wine virtual desktop window instead:

```sh
nix run .#midtown-madness-2 -- --windowed
```

The initial game display defaults to 1920×1080. On Wayland this matches the
fullscreen Xwayland surface and avoids an expensive compositor scaling pass.
To choose a different size (for example, on a lower-resolution display):

```sh
MIDTOWN_MADNESS_2_DESKTOP=1280x960 nix run .#midtown-madness-2
```

Configure other Wine settings:

```sh
nix run .#midtown-madness-2 -- --winecfg
```

Other arguments are passed to the game. For Wine diagnostics:

```sh
WINEDEBUG=+seh,+ddraw nix run .#midtown-madness-2
```

On NixOS, graphics drivers must be enabled (the module option does this).
Running on other Linux distributions may require their usual Nix/OpenGL
integration. Audio, controllers and actual multiplayer gameplay still need
verification on the machine where you play.

## Validation

The flake package builds successfully, the source hash is verified, and the
NixOS option was evaluated with the package present in `environment.systemPackages`.
The launcher was checked with ShellCheck, including help, path validation and
concurrent-launch protection. Fullscreen scaling was tested on gadol using a
temporary copy of the game and Wine prefix: the graphics menu filled the
1920×1080 display, and Sway reported a fullscreen Xwayland surface at that size.
Actual 3D gameplay and sound have **not** yet been verified.

The native DirectPlay package builds successfully. A 32-bit DirectPlay 4 probe
reproduced `DPERR_UNSUPPORTED` when hosting with Wine's built-in provider.
After installing the native components, a LAN test between gadol and tzedef
successfully discovered a session, joined it, created players and exchanged a
guaranteed message and acknowledgement. This verifies the networking APIs;
an actual multiplayer race still needs a game-level check.
