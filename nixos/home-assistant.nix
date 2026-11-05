# Define home automation behavior; add device integrations and automations here,
# keeping host provisioning in host profiles.
let
  hub =
    name: host: devices:
    {
      inherit name host;
      type = "tcp";
      port = 502;
    }
    // devices;
  sensor =
    attrs:
    {
      input_type = "holding";
      scan_interval = 1;
    }
    // attrs;
  pressure =
    name: slave:
    sensor {
      inherit name slave;
      address = 22;
      unit_of_measurement = "bar";
      data_type = "float32";
    };
  air =
    name: address: unit_of_measurement: extra:
    sensor (
      {
        inherit name address unit_of_measurement;
        slave = 40;
        data_type = "int16";
      }
      // extra
    );
  tenths = {
    scale = 0.1;
    precision = 1;
  };
  climate = name: address: {
    inherit name address;
    target_temp_register = address;
    input_type = "holding";
    data_type = "uint16";
    min_temp = 0;
    max_temp = 100;
    scale = 0.1;
  };
in
{
  flake.modules.nixos.home-assistant.services.home-assistant = {
    enable = true;
    config = {
      default_config = { };
      modbus = [
        (hub "pressure" "192.168.1.112" {
          sensors = [
            (pressure "hot" 10)
            (pressure "cold" 11)
          ];
        })
        (hub "air" "192.168.1.113" {
          sensors = [
            (air "room_hum" 0 "%" tenths)
            (air "room_temp" 1 "°C" tenths)
            (air "room_co2" 2 "ppm" { })
          ];
        })
        # Water 1
        (hub "water" "192.168.1.110" {
          climates = [
            (climate "cold" 3000)
            (climate "hot" 3001)
          ];
        })
      ];
    };
  };
}
