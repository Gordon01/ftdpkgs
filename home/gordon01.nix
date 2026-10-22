# Compose the personal macOS user profile; select modules and service instances
# here, keeping reusable implementations separate.
{ inputs, self, ... }:
{
  flake.homeConfigurations.gordon01 = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
    modules = [ self.homeModules.gordon01 ];
  };

  flake.homeModules = {
    gordon01 = { lib, pkgs, ... }: {
      imports = [
        self.homeModules.dev
        self.homeModules.ai
        self.homeModules.mlx-lm
        self.homeModules.open-webui
        self.homeModules.shell
        self.homeModules.gui
      ];

      home.stateVersion = "26.11";
      home.username = lib.mkDefault "alex";
      home.homeDirectory = lib.mkDefault "/Users/alex";

      home.packages = with pkgs; [
        maccy
        home-manager
      ];
      services.open-webui = {
        enable = true;
        openai.baseUrls = [ "http://localhost:8080/v1" ];
      };
      services.mlx-lm.enable = true;
    };
  };
}
