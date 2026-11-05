# Define the account baseline shared by Linux hosts; add common account policy
# here, keeping host-specific privileges and workloads in host profiles.
{
  inputs,
  linuxUser,
  self,
  ...
}:
{
  # Primary account name on Linux hosts, passed to every flake module.
  _module.args.linuxUser = "asergeev";

  flake.modules.nixos.asergeev = { pkgs, ... }: {
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    users.users.${linuxUser} = {
      isNormalUser = true;
      linger = true;
      extraGroups = [ "wheel" ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keyFiles = [ ../keys/id_mac.pub ];
    };
    programs.zsh.enable = true;

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.${linuxUser} = { osConfig, ... }: {
      imports = [
        self.modules.homeManager.dev
        self.modules.homeManager.shell
      ];
      home.stateVersion = osConfig.system.stateVersion;
    };
  };
}
