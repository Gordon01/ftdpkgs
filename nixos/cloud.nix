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
      networking.firewall = {
        allowedTCPPorts = [ config.home-manager.users.asergeev.services.rendezvous.httpPort ];
        allowedUDPPorts = [ config.home-manager.users.asergeev.services.rendezvous.udpPort ];
      };
      environment.systemPackages = with pkgs; [
        ghostty.terminfo
        htop
      ];
      services.openssh.enable = true;
      services.openssh.settings = {
        AuthenticationMethods = "publickey";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
      security.sudo.enable = true;
      security.sudo.wheelNeedsPassword = false;

      users.users.asergeev = {
        isNormalUser = true;
        linger = true;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keyFiles = [
          ../keys/id_mac.pub
          ../keys/id_home_win.pub
        ];
        shell = pkgs.zsh;
      };
      programs.zsh.enable = true;
      programs.nix-ld.enable = true;

      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.asergeev = {
        imports = [
          self.homeModules.shell
          inputs.cource.homeModules.rendezvous
        ];
        services.rendezvous.enable = true;
        home = {
          username = "asergeev";
          homeDirectory = "/home/asergeev";
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
