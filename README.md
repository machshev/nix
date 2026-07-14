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
