# Compose the personal macOS user profile; select modules and service instances
# here, keeping reusable implementations separate.
{
  config,
  inputs,
  self,
  ...
}:
let
  inherit (config) linuxUser;
in
{
  flake.homeConfigurations.alex = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      system = "aarch64-darwin";
      config.allowUnfreePredicate = pkg: inputs.nixpkgs.lib.getName pkg == "open-webui";
    };
    modules = [ self.homeModules.alex ];
  };

  flake.homeModules.alex = { lib, pkgs, ... }: {
    imports = [
      self.homeModules.dev
      self.homeModules.ai
      self.homeModules.mlx-lm
      self.homeModules.open-webui
      self.homeModules.shell
      self.homeModules.gui
      self.homeModules.darwin-devtool-shims
    ];

    home.stateVersion = "26.11";
    home.username = lib.mkDefault "alex";
    home.homeDirectory = lib.mkDefault "/Users/alex";

    home.packages = with pkgs; [
      maccy
    ];
    services.open-webui = {
      enable = true;
      openai.baseUrls = [ "http://localhost:8080/v1" ];
    };
    services.mlx-lm.enable = true;

    # Aliases follow each host's NixOS config; names resolve via Tailscale MagicDNS.
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = lib.listToAttrs (
        map
          (
            name:
            let
              host = self.nixosConfigurations.${name}.config;
            in
            lib.nameValuePair host.networking.hostName (
              {
                User = linuxUser;
                ForwardAgent = true;
              }
              // lib.optionalAttrs host.services.openssh.settings.X11Forwarding { ForwardX11 = true; }
            )
          )
          [
            "cloud"
            "wsl"
          ]
      );
    };
  };
}
