# Compose the WSL machine; add WSL-specific integration and workload choices here,
# keeping shared user configuration in reusable modules.
{
  inputs,
  linuxUser,
  self,
  ...
}:
{
  flake.nixosConfigurations.wsl = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      ({ pkgs, ... }: {
        imports = [
          self.modules.nixos.home-assistant
          self.modules.nixos.asergeev
          self.modules.nixos.base
          self.modules.nixos.network
          inputs.nixos-wsl.nixosModules.default
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

        environment.systemPackages = [ pkgs.xorg.xauth ];

        nixpkgs.hostPlatform = "x86_64-linux";
        system.stateVersion = "25.05";
        networking = {
          hostName = "wsl";
          proxy = {
            default = "http://127.0.0.1:10809";
            noProxy = "127.0.0.1,localhost,::1";
          };
        };

        nix.settings = {
          extra-platforms = [
            "x86_64-linux"
            "riscv64-linux"
          ];
          trusted-users = [ linuxUser ];
          substituters = [ "https://mirror.yandex.ru/nixos" ];
        };

        boot.binfmt.emulatedSystems = [ "riscv64-linux" ];
      })
    ];
  };
}
