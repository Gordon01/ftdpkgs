# Define home automation behavior; add device integrations and automations here,
# keeping host provisioning in host profiles.
{ ... }:
{
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
}
