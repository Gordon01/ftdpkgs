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
        self."homeModules".open-webui
        self.homeModules.shell
      ];

      home.stateVersion = "26.11";
      home.username = lib.mkDefault "alex";
      home.homeDirectory = lib.mkDefault "/Users/alex";

      home.packages = [ pkgs.home-manager ];
      services.open-webui.enable = true;
    };

    dev = { pkgs, ... }: {
      home.packages = with pkgs; [
        nixd
        nixfmt
      ];

      programs = {
        git.enable = true;
        git.settings.user = {
          name = "Alexander Sergeev";
          email = "etc9053@gmail.com";
        };
        tmux = {
          enable = true;
          mouse = true;
          newSession = true;
          secureSocket = true;
        };
      };
    };
  };
}
