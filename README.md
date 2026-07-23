# nix
Nix flake for my configs

## Haqor packages

The flake exposes the Haqor CLI, its standalone sync server, and the individual
workspace crates. Qatan runs `haqor-sync.service` on TCP port 8788. Its state
and generated bearer token are private to the `haqor-sync` system user;
retrieve the token after the first activation with:

```sh
ssh qatan sudo cat /var/lib/haqor-sync/token
```

Enter `http://qatan:8788` and that token in Haqor's **Progress sync** settings.

## MB7UJM APRS iGate

`mb7ujm` is a headless Raspberry Pi Zero 2 W host running Dire Wolf with:

- a USB sound card at ALSA `plughw:0,0`;
- GPIO 25 (physical pin 22) for PTT via `libgpiod`;
- a receive-only APRS-IS iGate configuration for `MB7UJM`; and
- deploy-rs updates over `mb7ujm.local`.

Enter the dedicated image-build shell:

```sh
nix develop .#mb7ujm
```

On an x86_64 Linux build machine, register the shell's static aarch64
interpreter, then build:

```sh
mb7ujm-enable-binfmt
mb7ujm-build-image
```

The registration is transient and does not couple the image build to any NixOS
host configuration. It disappears on reboot, or can be removed immediately
with `mb7ujm-disable-binfmt`. On an aarch64 build machine, the build helper works
without the registration step.

Write `result/sd-image/nixos-mb7ujm.img.zst` to the whole SD card, for example:

```sh
zstdcat result/sd-image/nixos-mb7ujm.img.zst \
  | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
```

Double-check `/dev/sdX`: this overwrites the selected device.

For the first headless boot, mount the SD card's `NIXOS_SD` partition and copy
the credentials from the build machine's active NetworkManager Wi-Fi
connection directly into NetworkManager's persistent profile directory:

```sh
mb7ujm-provision-wifi /path/to/NIXOS_SD
```

If the desired connection is not the only active Wi-Fi connection, give its
NetworkManager connection name as the second argument. The helper reads the
stored PSK with `nmcli --show-secrets`, asks for `sudo` to install a root-only
profile directly onto the card, and never places the credentials in this
repository, the Nix store, or the built image.

After the Pi appears on the network:

```sh
ssh jamesm@mb7ujm.local
sudo systemctl status direwolf
aplay -l
gpioinfo gpiochip0
```

If the sound card is not card 0 or the PTT circuit is active-low, adjust
[`hosts/mb7ujm/direwolf.conf`](hosts/mb7ujm/direwolf.conf). Dire Wolf is
deliberately configured as a receive-only iGate until the approved site
location, APRS-IS-to-RF filter, beacon, and path are added.

Deploy later configuration updates with:

```sh
deploy .#mb7ujm
```
