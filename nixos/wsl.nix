# Compose the WSL machine; add WSL-specific integration and workload choices here,
# keeping shared user configuration in reusable modules.
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
  flake.nixosModules.wsl =
    { pkgs, ... }:
    {
      imports = [
        self.nixosModules.home-assistant
        self.nixosModules.asergeev
        self.nixosModules.base
        self.nixosModules.network
      ];

      wsl = {
        enable = true;
        defaultUser = linuxUser;
        usbip.enable = true;
      };

      services.openssh.settings = {
        X11Forwarding = true;
        X11UseLocalhost = true;
      };

      environment.systemPackages = [
        pkgs.xorg.xauth
      ];

      system.stateVersion = "25.05";
      networking = {
        hostName = "wsl";
        proxy = {
          default = "http://127.0.0.1:10809";
          noProxy = "127.0.0.1,localhost,::1";
        };
      };

      home-manager.users.${linuxUser}.home.stateVersion = "25.05";

      nix.settings = {
        extra-platforms = [
          "x86_64-linux"
          "riscv64-linux"
        ];
        trusted-users = [ linuxUser ];
        substituters = [ "https://mirror.yandex.ru/nixos" ];
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
