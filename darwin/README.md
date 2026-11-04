## Quick start

Build the Darwin configuration:

```sh
darwin-rebuild build --flake .#Gordon01-MB
```

Apply it with `nix run .#deploy -- mac`.

## Linux builds

Linux derivations (`x86_64-linux`, `i686-linux`, `riscv64-linux`) are built remotely on the
WSL machine. The builder is configured through the Determinate nix-darwin module, which owns
`/etc/nix/nix.custom.conf` and `/etc/nix/machines`. The host name, systems and features come
from `nixosConfigurations.wsl`. The Nix daemon connects as root using `~alex/.ssh/id_ed25519`,
and the builder's host key is pinned in `keys/id_wsl.pub`. Update that file if the
WSL host key changes.

## Open WebUI

Open WebUI is configured to run as a launch agent after the system configuration is applied. Open <http://127.0.0.1:3000> in a browser to access it. Its persistent data and static files live in `~/.local/share/open-webui`.

The service logs are written to `~/.local/share/open-webui/logs/output.log` and
`~/.local/share/open-webui/logs/error.log` (under `$XDG_DATA_HOME` if configured).
The launch agent supplies the persistent data environment to the nixpkgs
`open-webui serve` command; the installed `open-webui` binary is not a wrapper.
No `open-webui-server` command or WebUI start/stop aliases are defined.

## MLX language model server

The launch agent is loaded but does not start automatically. Use these aliases to control it:

```sh
mlx-lm-start
mlx-lm-stop
```

To run it in the foreground instead, use `mlx-lm-server` and stop it with Ctrl-C.
