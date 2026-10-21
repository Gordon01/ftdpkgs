{ inputs, self, ... }:
{
  flake.nixosModules.cloud =
    {
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.disko.nixosModules.disko
        inputs.home-manager.nixosModules.home-manager
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
      environment.systemPackages = with pkgs; [
        ncurses
        htop
      ];
      services.openssh.enable = true;
      security.sudo.enable = true;
      security.sudo.wheelNeedsPassword = false;

      users.users.asergeev = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        hashedPassword = "$6$.Gu1a/Fy4GZe87HB$zPYtv4475JLWCpDqT1LBamWhQhBPV1feyPg8y8.XRZYuTqt/GDrFBvSwSY7hBDNmui6wkjAkqRYhmKV25EaPN1";
        openssh.authorizedKeys.keyFiles = [ ../keys/id_mac.pub ];
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
          stateVersion = "26.11";
        };
      };

      nix = {
        package = pkgs.nix;
        extraOptions = ''
          experimental-features = nix-command flakes
        '';
      };
    };

  flake.nixosConfigurations.cloud = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.nixosModules.cloud ];
  };
}
