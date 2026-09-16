# BeamNG software Vulkan launcher

From the repository root, with Steam running:

```sh
bash scripts/beamng-software-vulkan/run.sh
```

This runs the native Linux game with Mesa's CPU Vulkan driver (lavapipe,
reported as llvmpipe), suitable for trying the UI or multiplayer setup when
the physical GPU cannot supply the required Vulkan features. It does not
accelerate rendering on the GT 710. Expect very low performance in a level;
use the Lowest graphics preset and a small window.

The installed GT 710/NVK driver already provides Vulkan 1.2.354. BeamNG
0.39.4 rejects it because `drawIndirectCount`, `sparseBinding`, and
`sparseResidencyBuffer` are unavailable. Lavapipe supports these features,
but the game skips CPU devices. The small ICD forwarding library changes
only lavapipe's reported device type to discrete GPU. It does not invent
feature support or modify game binaries. All rendering still uses lavapipe.

The launcher sets the driver variables only for its child process, supplies
the native game's NSS/Vulkan runtime libraries, and uses `steam-run`.
Sway and the system graphics configuration are unaffected. No NixOS rebuild
or reboot is needed. The launcher builds against this repository's locked
Nixpkgs and requires the system Mesa lavapipe library at
`/run/opengl-driver/lib/libvulkan_lvp.so`.

Defaults:

- Game: `$XDG_DATA_HOME/Steam/steamapps/common/BeamNG.drive`, falling back to
  `$HOME/.local/share/Steam/steamapps/common/BeamNG.drive`.
- Separate user folder: `$XDG_DATA_HOME/BeamNG-software-test`, falling back
  to `$HOME/.local/share/BeamNG-software-test`.
- Four rendering threads, to leave CPU time for the desktop and game.

Override these with `BEAMNG_GAME_DIR`, `BEAMNG_USER_DIR`, and `LP_NUM_THREADS`.
Game arguments are forwarded. Avoid `-windowed`: this game's 0.39.4 native
argument parser crashes on it; set window size through the graphics menu.

Validation: built with compiler warnings treated as errors; Vulkan device
enumeration succeeds; BeamNG 0.39.4 creates its Vulkan device, initializes
Steam, and renders the first-run Online Features screen in Sway. A level
and multiplayer connection have not been tested. Complete the game's
online/privacy choices yourself before testing multiplayer. Mods installed
in your normal user folder are not automatically copied to this profile.
