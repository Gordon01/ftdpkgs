# Compose the cloud machine; add host provisioning and workload choices here,
# keeping shared account and network policy in reusable modules.
{ inputs, self, ... }:
{
  flake.nixosModules.cloud =
    {
      config,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.disko.nixosModules.disko
        self.nixosModules.asergeev
        self.nixosModules.network
      ];

      nixpkgs.hostPlatform = "x86_64-linux";
      system.stateVersion = "26.11";
      networking.hostName = "cloud";
      time.timeZone = "Europe/Moscow";

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

        loader.grub = {
          enable = true;
        };
      };

      networking.useDHCP = true;
      networking.firewall = {
        allowedTCPPorts = [ config.home-manager.users.asergeev.services.rendezvous.httpPort ];
        allowedUDPPorts = [ config.home-manager.users.asergeev.services.rendezvous.udpPort ];
      };
      environment.systemPackages = with pkgs; [
        htop
      ];

      security.sudo.enable = true;
      security.sudo.wheelNeedsPassword = false;

      users.users.asergeev = {
        openssh.authorizedKeys.keyFiles = [
          ../keys/id_home_win.pub
        ];
      };
      programs.nix-ld.enable = true;

      home-manager.users.asergeev = {
        imports = [
          inputs.cource.homeModules.rendezvous
        ];
        services.rendezvous.enable = true;
        home = {
          stateVersion = "26.11";
        };
      };

      nix = {
        package = pkgs.nix;
        settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
      };
    };

  flake.nixosConfigurations.cloud = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.nixosModules.cloud ];
  };
}
