## Home Manager

Apply the standalone Home Manager configuration without requiring `sudo`:

```sh
home-manager switch --flake .#alex
```

## macOS developer-tool shims

The personal macOS profile blocks Apple's developer-tool placeholders without
installing Command Line Tools or Xcode. A fallback directory is inserted directly
before `/usr/bin`, after the existing Nix profile directories:

```text
Nix tools -> blocking fallbacks -> /usr/bin
```

For example, the configured Nix Git continues to work. An unavailable `gcc` prints
an explanation to stderr and exits 127 instead of triggering Apple's installer.
Real tools added earlier in PATH, including by `nix shell nixpkgs#gcc` or a
project's `nix develop`, override the fallbacks. Unlike aliases, this also works
for commands invoked by child processes.

Protection covers login and non-login Zsh, including non-interactive sessions,
and processes inheriting their PATH. Independently launched GUI applications,
other independently configured shells, startup-file bypasses, and absolute paths
such as `/usr/bin/gcc` are not intercepted. `command -v gcc` still finds the
blocking executable; this does not make tool-presence probes report it missing.
`xcrun` and `xcode-select` are also blocked, including `xcode-select --install`.

The explicit 96-command inventory lives in
[darwin-devtool-shims.nix](./darwin-devtool-shims.nix). After macOS upgrades,
review it against the two Apple shim hard-link groups:

```sh
find /usr/bin -type f -samefile /usr/bin/gcc -print
find /usr/bin -type f -samefile /usr/bin/xcodebuild -print
```

The inventory also includes the separate `xcrun` and `xcode-select` executables.
It is built by Nix, not discovered during shell startup. The blockers are kept
outside normal package profiles so they cannot collide with real Nix tools.
