# Compose the WSL machine; add WSL-specific integration and workload choices here,
# keeping shared user configuration in reusable modules.
{ self, inputs, ... }:
{
  flake.nixosModules.wsl =
    {
      pkgs,
      ...
    }:
    {
      imports = [
        self.nixosModules.home-assistant
        self.nixosModules.asergeev
        self.nixosModules.network
      ];

      wsl = {
        enable = true;
        defaultUser = "asergeev";
        usbip.enable = true;
      };

      system.stateVersion = "25.05";
      networking.hostName = "nixos-wsl";
      time.timeZone = "Europe/Moscow";
      programs.nix-ld.enable = true;

      home-manager.users.asergeev = {
        imports = [ self.homeModules.dev ];
        home.stateVersion = "25.05";
      };

      nix = {
        package = pkgs.nix;
        extraOptions = ''
          experimental-features = nix-command flakes
          extra-platforms = x86_64-linux riscv64-linux
        '';
        settings = {
          trusted-users = [ "asergeev" ];
          substituters = [ "https://mirror.yandex.ru/nixos" ];
        };
      };

      boot.binfmt.emulatedSystems = [ "riscv64-linux" ];
    };

  flake.nixosConfigurations.wsl = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.wsl
      inputs.nixos-wsl.nixosModules.default
      { nixpkgs.hostPlatform = "x86_64-linux"; }
    ];
  };
}
