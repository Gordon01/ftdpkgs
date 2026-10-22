# Define the account baseline shared by Linux hosts; add common account policy
# here, keeping host-specific privileges and workloads in host profiles.
{ inputs, self, ... }:
{
  flake.nixosModules.asergeev = { pkgs, ... }: {
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    users.users.asergeev = {
      isNormalUser = true;
      linger = true;
      extraGroups = [ "wheel" ];
      shell = pkgs.zsh;
    };
    programs.zsh.enable = true;

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.asergeev = {
      imports = [ self.homeModules.shell ];
      home = {
        username = "asergeev";
        homeDirectory = "/home/asergeev";
      };
    };
  };
}
