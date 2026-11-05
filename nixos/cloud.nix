# Compose the cloud machine; add host provisioning and workload choices here,
# keeping shared account and network policy in reusable modules.
{
  inputs,
  linuxUser,
  self,
  ...
}:
{
  flake.nixosConfigurations.cloud = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      ({ config, ... }: {
        imports = [
          inputs.disko.nixosModules.disko
          self.modules.nixos.asergeev
          self.modules.nixos.base
          self.modules.nixos.network
        ];

        nixpkgs.hostPlatform = "x86_64-linux";
        system.stateVersion = "26.11";
        networking.hostName = "cloud";

        disko.devices.disk.main = {
          type = "disk";
          device = "/dev/vda";
          content = {
            type = "gpt";
            partitions = {
              bios = {
                size = "4M";
                type = "EF02";
              };
              swap = {
                size = "4G";
                content.type = "swap";
              };
              root = {
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };

        boot = {
          initrd.availableKernelModules = [
            "virtio_pci"
            "virtio_blk"
            "virtio_net"
            "ahci"
            "usbhid"
          ];
          loader.grub.enable = true;
        };

        networking.firewall = {
          allowedTCPPorts = [ config.home-manager.users.${linuxUser}.services.rendezvous.httpPort ];
          allowedUDPPorts = [ config.home-manager.users.${linuxUser}.services.rendezvous.udpPort ];
        };

        security.sudo.wheelNeedsPassword = false;

        users.users.${linuxUser}.openssh.authorizedKeys.keyFiles = [ ../keys/id_home_win.pub ];

        home-manager.users.${linuxUser} = {
          imports = [ inputs.cource.homeModules.rendezvous ];
          services.rendezvous.enable = true;
        };
      })
    ];
  };
}
