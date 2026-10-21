## Initial installation

```sh
nix run github:nix-community/nixos-anywhere -- \
  --flake .#cloud \
  --target-host user@host \
  --build-on remote
```

## Apply configuration updates

```sh
nix run nixpkgs#nixos-rebuild -- switch \
  --flake .#cloud \
  --build-host user@host \
  --target-host user@host \
  --elevate sudo \
  --ask-elevate-password
```
