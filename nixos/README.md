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

## GitVerse runner

The cloud configuration starts a persistent NixOS container named `gitverse`
using systemd-nspawn, not Docker or Podman. It runs the official GitVerse runner
6.0.2 with native execution labels. The runner's "host" is the container.
Docker actions, workflow service containers and Ubuntu-specific tools are not
supported.

### Module configuration

Import `nixosModules.gitverse-runner` and enable it on a NixOS host:

```nix
services.gitverse-runner = {
  enable = true;
  settings = {
    tokenFile = "/var/lib/gitverse-runner/token";
    name = "cloud-nixos";
    runner.capacity = 1;
  };
};
```

The cloud module already imports and enables it. Importing the runner module
alone does not create a container or enable NAT.
The official binary is a non-flake `gitverse-runner` input, pinned in
`flake.lock`; the package does not download it with `fetchurl`.

`settings.tokenFile` is required when the service is enabled. Literal
registration tokens are not supported. Do not commit real tokens.
Use a dedicated directory for `tokenFile`: its parent
directory is mounted read-only in the container.

`settings.name`, `settings.url` and `settings.labels` control registration.
Labels must explicitly use `:host`, because this module has no container
runtime for jobs. The remaining settings are passed to the runner's native
YAML configuration, overriding defaults such as `runner.capacity = 1` and
`runner.envs.NIX_REMOTE = "daemon"`. `tokenFile` is a module-level
registration setting, not an undocumented key sent to the runner YAML.

### Provision and register

Before deploying, obtain a **repository** runner registration token from
**Settings → Runners → Add runner** in GitVerse. Repository scope comes from
this token, not a repository URL in the Nix configuration. Do not put the token
in this repository, a Nix expression, the Nix store or a command argument.

On the cloud host, provision a root-only environment file:

```sh
sudo install -d -m 0700 /var/lib/gitverse-runner
sudo install -m 0600 /dev/null /var/lib/gitverse-runner/token
sudoedit /var/lib/gitverse-runner/token
```

Enter the following, replacing the placeholder in the editor:

```sh
TOKEN=your-repository-runner-registration-token
```

Apply configuration updates using the command above. The secret directory is
mounted read-only with UID mapping, so container root can read the host
root-owned file despite the container's private user namespace. The service
manager reads it before dropping to the runner's unprivileged dynamic user.
The token file must exist before starting the service; missing or invalid
credentials produce service errors rather than an unregistered fallback.

Registration connects to `https://gitverse.ru`, not the retired `/sc` endpoint.
The service reuses its saved registration across restarts. Replacing the token
or changing labels triggers re-registration on the next service start.

The container uses `192.168.100.1` on the host and `192.168.100.2` in the
container. Confirm these addresses do not overlap your cloud network before
deployment. Outbound access uses NAT on `ve-gitverse`, with no forwarded
inbound ports or trusted firewall interface. DNS uses `1.1.1.1` and `9.9.9.9`.

### Status and smoke test

On the cloud host:

```sh
sudo systemctl status container@gitverse.service
sudo nixos-container run gitverse -- systemctl status gitea-runner-gitverse.service
sudo nixos-container run gitverse -- journalctl -u gitea-runner-gitverse.service -n 100 --no-pager
```

Verify that `cloud-nixos` is online in the repository's runner settings. Add
this workflow to that repository's `.gitverse/workflows/runner-smoke.yml`:

```yaml
name: Cloud runner smoke test
on: workflow_dispatch
jobs:
  smoke:
    runs-on: cloud-nixos
    steps:
      - name: Check native tools and build with Nix
        run: |
          set -eu
          git --version
          node --version
          nix --version
          test "$(id -u)" -ne 0
          test ! -e /home/asergeev/.ssh
          test ! -r /run/gitverse-registration/token
          nix build --no-link --print-out-paths nixpkgs#hello
```

The first smoke build may need to fetch the default flake registry and
nixpkgs. Production workflows should pin their dependencies with a lock file.
Run the workflow and inspect its logs; checking that the service is running
alone does not verify workflow execution or Nix daemon access.

To check persistence, compare the runner ID in GitVerse before and after:

```sh
sudo systemctl restart container@gitverse.service
```

It should reconnect as the same runner without creating a new registration.

### Rotation and removal

To rotate the registration token, edit the existing file without replacing its
permissions, then restart the runner:

```sh
sudoedit /var/lib/gitverse-runner/token
sudo nixos-container run gitverse -- systemctl restart gitea-runner-gitverse.service
```

Label changes are applied through a configuration rebuild. Re-registration
may leave an old offline entry in GitVerse; remove obsolete entries in the
repository's runner settings.

To remove the runner, stop the container, remove its module import from the
cloud configuration (or set `services.gitverse-runner.enable = false`) and
rebuild. Remove its registration in the GitVerse UI.
Only after deciding that saved workspaces and caches are no longer needed,
remove the specific container state directory
`/var/lib/nixos-containers/gitverse`, the per-container Nix profiles and GC
roots under `/nix/var/nix/{profiles,gcroots}/per-container/gitverse`, and
`/var/lib/gitverse-runner/token`. Do not delete shared host Nix store paths.

### Isolation and resource limits

This configuration is for **trusted repository jobs**, not hostile code:

- It isolates the runner's filesystem, processes, network and user IDs from
  normal host sessions, but shares the host kernel.
- Standard NixOS containers expose the host Nix store/database and daemon
  socket. A read-only socket mount still permits daemon requests. Jobs use
  that daemon as unprivileged clients; no runner identity is added to the
  host's trusted users, and host Nix build sandboxing remains enabled.
- Host store contents are visible. Prefer `settings.tokenFile` to avoid putting
  the registration token in the Nix store.
  Private networking is not an egress filter: jobs can reach network services,
  including host services allowed by its firewall.
- Jobs share runner identity, generated runner credentials, persistent
  workspace and caches. Service state lives under
  `/var/lib/gitea-runner` inside the container. This is not a fresh sandbox
  per job; the registration environment is not a secret boundary from jobs.
- The runner has no sudo or container-runtime access. Nix daemon settings,
  privileged cache configuration and host administration must remain in the
  declarative host configuration.
- One job runs at a time, with no explicit CPU, memory or disk caps. Nix
  builds use the host daemon's normal scheduling. CI can contend with other
  host services and fill the shared disk.

Configuration evaluation on macOS does not establish Linux runtime behavior.
Before relying on this runner, complete the online registration, workflow,
file-isolation and restart checks above on the cloud host.
