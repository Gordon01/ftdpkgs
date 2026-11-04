# Configuration

- The Mac and its remote builder are configured in [darwin/gordon01.nix](darwin/gordon01.nix); Linux hosts and shared modules are in [nixos/](nixos/).
- [home/alex.nix](home/alex.nix) derives SSH aliases from NixOS hostnames and `linuxUser`, defined in [nixos/asergeev.nix](nixos/asergeev.nix).

# Nix workflow

1. Run `nix flake check` before and after changes. It does not ensure system or Home Manager profiles were built; validate affected profiles separately when needed.
2. Stage new files used by this Git-backed flake before running Nix; untracked files are excluded. Write Nix files as flake-parts modules.
3. The Mac uses WSL for remote Linux builds; see [darwin/README.md](darwin/README.md). Report if required validation is unavailable. `nix run .#deploy` switches all targets by default and is not a validation command; see [README.md](README.md).

# General guidance

Use Nix to obtain missing tools. Prefer `jq` and `ripgrep` when useful.

# References

- flake-parts: https://flake.parts/options/flake-parts.html
