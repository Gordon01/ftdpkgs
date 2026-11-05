# Compose the personal macOS user profile; select modules and service instances
# here, keeping reusable implementations separate.
{
  inputs,
  linuxUser,
  self,
  ...
}:
{
  flake.homeConfigurations.alex = inputs.home-manager.lib.homeManagerConfiguration {
    # Reuse the Mac's nixpkgs instance, including its unfree package policy.
    inherit (self.darwinConfigurations."Gordon01-MB") pkgs;
    modules = [ self.modules.homeManager.alex ];
  };

  flake.modules.homeManager.alex = { lib, pkgs, ... }: {
    imports = [
      self.modules.homeManager.dev
      self.modules.homeManager.ai
      self.modules.homeManager.shell
      self.modules.homeManager.gui
    ];

    home.stateVersion = "26.11";
    home.username = lib.mkDefault "alex";
    home.homeDirectory = lib.mkDefault "/Users/alex";

    home.packages = [ pkgs.maccy ];
    services.open-webui.enable = true;
    services.mlx-lm.enable = true;

    # Aliases follow each host's NixOS config; names resolve via Tailscale MagicDNS.
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = lib.mapAttrs' (
        _: host:
        lib.nameValuePair host.config.networking.hostName {
          User = linuxUser;
          ForwardAgent = true;
          ForwardX11 = lib.mkIf host.config.services.openssh.settings.X11Forwarding true;
        }
      ) self.nixosConfigurations;
    };
  };
}
