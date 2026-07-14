# nix
Nix flake for my configs

## Haqor packages

The flake exposes the Haqor CLI, its `sync-server` wrapper, and the individual
workspace crates. For an explicit LAN-server run on Qatan, use:

```sh
nix run ~/base/nix#haqor-sync-server -- --token "choose-a-long-random-secret"
```
