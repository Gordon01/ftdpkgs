# ftdpkgs

This repository consolidates all of my computer experience into a single, ready-to-use setup. Thanks to the Nix package manager, everything is portable and will continue to work for many years.

It is like another Awesome list tailored to me and my friends.

It contains:

- links to my other repos and re-exported binaries from them
- configuration for my NixOS machines
- configuration for my macOS machines
- reusable `flake-parts` modules

## Structure

- [darwin/](./darwin/) and [nixos/](./nixos/) contain host configurations and shared system modules.
- [home/](./home/) contains Home Manager profiles and services.
- [modules/](./modules/) contains deployment and formatting integration.

## Apply configurations

```sh
nix run .#deploy                 # all: cloud, mac, wsl
nix run .#deploy -- mac wsl      # selected targets, in order
```

`mac` runs `sudo darwin-rebuild switch`. NixOS hosts are built and switched on the hosts
themselves through `nixos-rebuild --target-host/--build-host`.

## OpenCode with GitHub Copilot

Then start `opencode`, run `/connect`, select **GitHub Copilot**.
Use `/models` to select a model, or list them with:

```sh
opencode models github-copilot
```
