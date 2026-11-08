## Quick start

Build the Darwin configuration:

```sh
darwin-rebuild build --flake .#Gordon01-MB
```

Apply it with `nix run .#deploy -- mac`.

## Homebrew

`nix-homebrew` bootstraps native Apple Silicon Homebrew in `/opt/homebrew`.

After applying the configuration, verify the formula directly:

```sh
brew list --versions tree
/opt/homebrew/bin/tree --version
```

## macOS developer-tool blockers

The [devtool-blockers.nix](./devtool-blockers.nix) module blocks Apple's developer-tool
placeholders from triggering the Command Line Tools installer. It uses nix-darwin's
[`environment.systemPath`](https://nix-darwin.github.io/nix-darwin/manual/index.html#opt-environment.systemPath)
to order PATH without custom shell hooks:

```text
Nix profiles -> blocking fallbacks -> /usr/local/bin -> /usr/bin -> ...
```

Blocked commands print an explanation and exit 127, including `xcrun` and
`xcode-select --install`. Nix tools and tools prepended by `nix shell` or
`nix develop` take precedence; tools in `/usr/local/bin` do not.

Apply the Darwin configuration and start a fresh shell to enable protection;
standalone Home Manager does not enable it. Absolute paths such as `/usr/bin/gcc`
and applications that do not inherit nix-darwin's PATH bypass it.
`command -v` still finds blockers, so presence checks do not report tools missing.
Review the module's command inventory after macOS upgrades.

## Linux builds

Linux derivations (`x86_64-linux`, `i686-linux`, `riscv64-linux`) are built remotely on the
WSL machine. The Nix daemon connects as root using `~alex/.ssh/id_ed25519`,
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
