# Compose this Mac's system profile; add machine-specific settings and module
# selections here, keeping reusable desktop preferences in the GUI module.
{ self, inputs, ... }:
{
  flake.darwinConfigurations."Gordon01-MB" = inputs.nix-darwin.lib.darwinSystem {
    modules = [
      self.modules.darwin.gui
      ({ pkgs, ... }: {
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
        home-manager.users.alex = self.homeModules.gordon01;
        users.users.alex.home = "/Users/alex";
        system.primaryUser = "alex";
        system.defaults.screencapture.location = "/Users/alex/Pictures/Screenshots";

        services.tailscale.enable = true;

        # Nix is managed outside nix-darwin by Determinate Nix installer.
        nix.enable = false;
        # Keep this unchanged unless intentionally migrating nix-darwin state.
        system.stateVersion = 6;
        system.configurationRevision = self.rev or self.dirtyRev or null;
        nixpkgs.hostPlatform = "aarch64-darwin";
      })
    ];
  };
}
