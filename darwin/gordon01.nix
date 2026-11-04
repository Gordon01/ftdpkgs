# Compose this Mac's system profile; add machine-specific settings and module
# selections here, keeping reusable desktop preferences in the GUI module.
{
  config,
  inputs,
  self,
  ...
}:
let
  inherit (config) linuxUser;
  wsl = self.nixosConfigurations.wsl.config;
in
{
  flake.darwinConfigurations."Gordon01-MB" = inputs.nix-darwin.lib.darwinSystem {
    modules = [
      self.modules.darwin.gui
      self.modules.darwin.devtool-blockers
      inputs.determinate.darwinModules.default
      ({ lib, pkgs, ... }: {
        imports = [ inputs.home-manager.darwinModules.home-manager ];

        # Available to all users on this Mac.
        environment.systemPackages = with pkgs; [
          git
          tmux
          vim
        ];

        security.pam.services.sudo_local.touchIdAuth = true;
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.alex = self.homeModules.alex;
        users.users.alex.home = "/Users/alex";
        system.primaryUser = "alex";
        system.defaults.screencapture.location = "/Users/alex/Pictures/Screenshots";

        services.tailscale.enable = true;

        # Nix is installed by Determinate; its module owns /etc/nix/nix.custom.conf.
        determinateNix = {
          enable = true;
          customSettings = {
            substituters = [ "https://cache.nixos.org/" ];
            trusted-users = [ "@admin" ];
            builders-use-substitutes = true;
          };

          # Linux builds run on the WSL machine as the shared Linux account.
          distributedBuilds = true;
          buildMachines = [
            {
              inherit (wsl.networking) hostName;
              protocol = "ssh-ng";
              sshUser = linuxUser;
              # The daemon runs as root; this key is authorized via id_mac.pub.
              sshKey = "/Users/alex/.ssh/id_ed25519";
              systems = lib.unique ([ wsl.nixpkgs.hostPlatform.system ] ++ wsl.nix.settings.extra-platforms);
              supportedFeatures = wsl.nix.settings.system-features;
              # Core count of the WSL machine.
              maxJobs = 32;
            }
          ];
        };
        programs.ssh.knownHosts.${wsl.networking.hostName}.publicKeyFile = ../keys/id_wsl.pub;

        # Keep this unchanged unless intentionally migrating nix-darwin state.
        system.stateVersion = 6;
        system.configurationRevision = self.rev or self.dirtyRev or null;
        nixpkgs.hostPlatform = "aarch64-darwin";
        nixpkgs.config.allowUnfreePredicate = pkg: lib.getName pkg == "open-webui";
      })
    ];
  };
}
