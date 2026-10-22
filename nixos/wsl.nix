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
        self.nixosModules.tailscale
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

  flake.nixosModules.asergeev = { pkgs, ... }: {
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
      imports = [
        self.homeModules.shell
        self.homeModules.dev
      ];
      home = {
        username = "asergeev";
        homeDirectory = "/home/asergeev";
        stateVersion = "25.05";
      };
    };
    nix.settings.trusted-users = [ "asergeev" ];
  };

  flake.nixosModules.home-assistant = {
    services.home-assistant = {
      enable = true;
      config = {
        default_config = { };

        modbus = [
          {
            name = "pressure";
            type = "tcp";
            host = "192.168.1.112";
            port = 502;
            sensors = [
              {
                name = "hot";
                slave = 10;
                address = 22;
                input_type = "holding";
                unit_of_measurement = "bar";
                data_type = "float32";
                scan_interval = 1;
              }
              {
                name = "cold";
                slave = 11;
                address = 22;
                input_type = "holding";
                unit_of_measurement = "bar";
                data_type = "float32";
                scan_interval = 1;
              }
            ];
          }

          {
            name = "air";
            type = "tcp";
            host = "192.168.1.113";
            port = 502;
            sensors = [
              {
                name = "room_hum";
                slave = 40;
                address = 0;
                input_type = "holding";
                unit_of_measurement = "%";
                data_type = "int16";
                scale = 0.1;
                precision = 1;
                scan_interval = 1;
              }
              {
                name = "room_temp";
                slave = 40;
                address = 1;
                input_type = "holding";
                unit_of_measurement = "°C";
                data_type = "int16";
                scale = 0.1;
                precision = 1;
                scan_interval = 1;
              }
              {
                name = "room_co2";
                slave = 40;
                address = 2;
                input_type = "holding";
                unit_of_measurement = "ppm";
                data_type = "int16";
                scan_interval = 1;
              }
            ];
          }

          {
            name = "water";
            type = "tcp";
            host = "192.168.1.110"; # Water 1
            port = 502;
            climates = [
              {
                name = "cold";
                address = 3000;
                input_type = "holding";
                data_type = "uint16";
                min_temp = 0;
                max_temp = 100;
                scale = 0.1;
                target_temp_register = 3000;
              }
              {
                name = "hot";
                address = 3001;
                input_type = "holding";
                data_type = "uint16";
                min_temp = 0;
                max_temp = 100;
                scale = 0.1;
                target_temp_register = 3001;
              }
            ];
          }

        ];
      };
    };
  };

  flake.nixosConfigurations.wsl = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.wsl
      inputs.nixos-wsl.nixosModules.default
      inputs.home-manager.nixosModules.home-manager
      { nixpkgs.hostPlatform = "x86_64-linux"; }
    ];
  };
}
