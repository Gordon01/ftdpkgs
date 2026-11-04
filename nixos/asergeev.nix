# Define the account baseline shared by Linux hosts; add common account policy
# here, keeping host-specific privileges and workloads in host profiles.
{
  config,
  inputs,
  lib,
  self,
  ...
}:
let
  inherit (config) linuxUser;
in
{
  options.linuxUser = lib.mkOption {
    type = lib.types.str;
    default = "asergeev";
    description = "Primary account name on Linux hosts.";
  };

  config.flake.nixosModules.asergeev =
    { pkgs, ... }:
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      users.users.${linuxUser} = {
        isNormalUser = true;
        linger = true;
        extraGroups = [ "wheel" ];
        shell = pkgs.zsh;
        openssh.authorizedKeys.keyFiles = [
          ../keys/id_mac.pub
        ];
      };
      programs.zsh.enable = true;

      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${linuxUser} = {
        imports = [
          self.homeModules.dev
          self.homeModules.shell
        ];
        home = {
          username = linuxUser;
          homeDirectory = "/home/${linuxUser}";
        };
      };
    };
}
