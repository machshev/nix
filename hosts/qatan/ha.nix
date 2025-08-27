{
  config,
  pkgs-unstable,
  ...
}: {
  networking.firewall.allowedTCPPorts = [
    8123 # Home assistant
    1883 # Mosquitto
    1880 # zigbee2mqtt UI
  ];

  services.zigbee2mqtt = {
    enable = true;
    package = pkgs-unstable.zigbee2mqtt;
    settings = {
      homeassistant = true;
      permit_join = true;
      serial = {
        port = "tcp://10.140.0.20:6638";
        baudrate = 115200;
        adapter = "ember";
        disable_led = false;
      };
      advanced.transmit_power = 20;
      frontend = {
        enabled = true;
        port = 1880;
      };
      devices = {
        "0x70b3d52b6010191f" = {
          friendly_name = "Pantry Plug";
        };
        "0x70b3d52b60101bc6" = {
          friendly_name = "Ma Bedroom Plug";
        };
        "0x70b3d52b60101bf3" = {
          friendly_name = "Joseph Desk Plug";
        };
        "0x70b3d52b601304c7" = {
          friendly_name = "Main Bedroom Lamp Plug";
        };
        "0x70b3d52b6013050c" = {
          friendly_name = "Lydia Plug";
        };
        "0x70b3d52b6013061a" = {
          friendly_name = "Garage Plug";
        };
        "0x70b3d52b60130759" = {
          friendly_name = "Pa Bedroom Plug";
        };
        "0x70b3d52b6013092c" = {
          friendly_name = "Landing Plug";
        };
        "0x70b3d52b6013665a" = {
          friendly_name = "Dining Room Plug";
        };
        "0x70b3d52b6013e606" = {
          friendly_name = "Porch Plug";
        };
        "0x70b3d52b6013ea19" = {
          friendly_name = "Joseph Clock Plug";
        };
        "0x70b3d52b6013ea36" = {
          friendly_name = "Main Bedroom Spair Plug";
        };
        "0xa4c138002ea566eb" = {
          friendly_name = "Lydia Bedroom TH";
        };
        "0xa4c13800e03e57d5" = {
          friendly_name = "Utility TH";
        };
        "0xa4c13838ba7d8851" = {
          friendly_name = "Main Bedroom TRV";
        };
        "0xa4c1383f19e3f83e" = {
          friendly_name = "Landing TH";
        };
        "0xa4c13842b8f117aa" = {
          friendly_name = "Main Bedroom TH";
        };
        "0xa4c1385a32ff17ca" = {
          friendly_name = "Pa Bedroom TH";
        };
        "0xa4c13871ad72c96a" = {
          friendly_name = "Office TH";
        };
        "0xa4c13898499173f6" = {
          friendly_name = "boiler";
        };
        "0xa4c13899d44484c1" = {
          friendly_name = "Joseph Bedroom TH";
        };
        "0xa4c138a74c3c4693" = {
          friendly_name = "Upstairs Bathroom TH";
        };
        "0xa4c138c88c8f6bee" = {
          friendly_name = "Ma Bedroom TH";
        };
        "0xa4c138e6138436e9" = {
          friendly_name = "Kitchen TH";
        };
        "0xa4c138eeb2a3457b" = {
          friendly_name = "Dining Room TH";
        };
        "0xa4c138f029d46b66" = {
          friendly_name = "Loft TH";
        };
        "0xa4c138f25967576a" = {
          friendly_name = "Lyda Bedroom TRV";
        };
        "0xf84477fffe935142" = {
          friendly_name = "Upstairs Bathroom Prox";
        };
        "0xa4c13835b74a7629" = {
          friendly_name = "Pantry Light Switch";
        };
        "0xa4c138a174191ad0" = {
          friendly_name = "Porch Light Switch";
        };
      };
    };
  };
  systemd.services.zigbee2mqtt.serviceConfig.SystemCallFilter = ["@pkey"];

  services.mosquitto = {
    enable = true;
  };

  services.home-assistant = {
    enable = true;
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = {};

      "automation manual" = [];
      "automation ui" = "!include automations.yaml";

      "scene manual" = [];
      "scene ui" = "!include scenes.yaml";

      "script manual" = [];
      "script ui" = "!include scripts.yaml";
    };

    extraComponents = [
      "alexa"
      "mqtt"
      "default_config"
      "esphome"
      "met"
      "nest"
      "reolink"
      "tuya"
      "velux"
    ];

    extraPackages = ps:
      with ps; [
        isal
        ibeacon-ble
      ];
  };

  systemd.tmpfiles.rules = [
    "f ${config.services.home-assistant.configDir}/automations.yaml 0755 hass hass"
    "f ${config.services.home-assistant.configDir}/scenes.yaml 0755 hass hass"
    "f ${config.services.home-assistant.configDir}/scripts.yaml 0755 hass hass"
  ];
}
