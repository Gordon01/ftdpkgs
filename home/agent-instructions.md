# Mac Nix environment

These are machine-wide notes for working on this Mac. Treat the configuration as the source of truth if any detail here becomes stale.

## Host and configuration

- The Mac host is `Gordon01-MB` (`aarch64-darwin`), configured with nix-darwin and Home Manager.
- Nix is installed and managed by Determinate Nix.
- The configuration repository is `~/Documents/development/nix/ftdpkgs`. Use master branch.
- The host and builder definitions are in `darwin/gordon01.nix` and `nixos/wsl.nix`.
- This file is managed by Home Manager.

## Remote Linux builder

- Linux builds are distributed to the NixOS WSL machine named `wsl` over `ssh-ng`. Its host platform is `x86_64-linux`, and its default user is `asergeev`.
- The configured SSH key path is `/Users/alex/.ssh/id_ed25519`. Never read, print, copy, or expose private key contents.
- The builder advertises `x86_64-linux` and `riscv64-linux`; check the NixOS host definition before assuming support for other systems.

## Validation and deployment

- When using the Git-backed flake, stage new files referenced by Nix before evaluating or building, because untracked files are excluded.
