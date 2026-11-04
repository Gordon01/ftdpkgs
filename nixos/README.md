## Initial installation

```sh
nix run github:nix-community/nixos-anywhere -- \
  --flake .#cloud \
  --target-host user@host \
  --build-on remote
```

## Apply configuration updates

Each host builds its own system over SSH through the `cloud`/`wsl` SSH aliases:

```sh
nix run .#deploy -- cloud
nix run .#deploy -- wsl
```
