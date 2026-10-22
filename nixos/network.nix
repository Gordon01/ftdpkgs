{ ... }: {
  flake.nixosModules.network = { pkgs, ... }: {
    services.tailscale.enable = true;

    services.openssh.enable = true;
    services.openssh.settings = {
      AuthenticationMethods = "publickey";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };

    environment.systemPackages = [
      pkgs.ghostty.terminfo
    ];

    users.users.asergeev = {
      openssh.authorizedKeys.keyFiles = [
        ../keys/id_mac.pub
      ];
    };
  };
}
