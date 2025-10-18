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
      mqtt = {
        base_topic = "zigbee2mqtt";
        server = "!${config.sops.secrets."z2m.yaml".path} server";
        user = "!${config.sops.secrets."z2m.yaml".path} user";
        password = "!${config.sops.secrets."z2m.yaml".path} password";
        version = 5;
      };
      homeassistant = {
        enabled = true;
        discovery_topic = "homeassistant";
        experimental_event_entities = true;
      };
      permit_join = true;
      serial = {
        port = "tcp://10.140.0.20:6638";
        baudrate = 115200;
        adapter = "zstack";
        disable_led = false;
      };
      advanced = {
        channel = 26;
        pan_id = 62355;
        extended_pan_id = [3 237 123 77 223 225 63 81]; # 0x03ed7b4ddfe13f51
        transmit_power = 20;
        last_seen = "ISO_8601";
        elapsed = true;
      };
      frontend = {
        enabled = true;
        port = 1880;
      };
      devices = {
        # Loft
        "0xa4c138f029d46b66" = {
          friendly_name = "Loft TH";
          retain = true;
        };
        "0xa4c13898499173f6" = {
          friendly_name = "boiler";
        };

        # Main Bedroom
        "0xa4c13842b8f117aa" = {
          friendly_name = "Main Bedroom TH";
          retain = true;
        };
        "0xa4c13838ba7d8851" = {
          friendly_name = "Main Bedroom TRV";
        };

        "0x70b3d52b601304c7" = {
          friendly_name = "Main Bedroom Lamp Plug";
        };
        "0x70b3d52b6013ea36" = {
          friendly_name = "Main Bedroom Spair Plug";
        };

        # Ma room
        "0xa4c138c88c8f6bee" = {
          friendly_name = "Ma Bedroom TH";
          retain = true;
        };
        "0xa4c138f25967576a" = {
          friendly_name = "Ma Bedroom TRV";
        };

        # Hall
        "0x70b3d52b60101bc6" = {
          friendly_name = "Hall Plug";
        };

        # Pa room
        "0xa4c1385a32ff17ca" = {
          friendly_name = "Pa Bedroom TH";
          retain = true;
        };
        "0xa4c138248270865d" = {
          friendly_name = "Pa Bedroom TRV";
        };

        "0x70b3d52b60130759" = {
          friendly_name = "Pa Bedroom Plug";
        };

        "0x6cfd22fffe197c11" = {
          friendly_name = "Wetroom Prox";
        };
        # Joseph room
        "0xa4c13899d44484c1" = {
          friendly_name = "Joseph Bedroom TH";
          retain = true;
        };
        "0xa4c138e5dd77d1ed" = {
          friendly_name = "Joseph Bedroom TRV";
        };

        "0x70b3d52b6013ea19" = {
          friendly_name = "Joseph Clock Plug";
        };
        "0x70b3d52b60101bf3" = {
          friendly_name = "Joseph Desk Plug";
        };

        # Lydia room
        "0xa4c138002ea566eb" = {
          friendly_name = "Lydia Bedroom TH";
          retain = true;
        };
        "0xa4c138fff4965e30" = {
          friendly_name = "Lyda Bedroom TRV";
        };

        "0x70b3d52b6013050c" = {
          friendly_name = "Lydia Plug";
        };

        # Pantry
        "0xa4c13835b74a7629" = {
          friendly_name = "Pantry Light Switch";
        };

        # Garage
        "0x70b3d52b6013061a" = {
          friendly_name = "Garage Plug";
        };

        # Landing
        "0xa4c1383f19e3f83e" = {
          friendly_name = "Landing TH";
          retain = true;
        };
        "0x70b3d52b6013092c" = {
          friendly_name = "Landing Plug";
        };

        # Utility
        "0xa4c13800e03e57d5" = {
          friendly_name = "Utility TH";
          retain = true;
        };

        # Office
        "0xa4c13871ad72c96a" = {
          friendly_name = "Office TH";
          retain = true;
        };

        # Kitchen
        "0xa4c138e6138436e9" = {
          friendly_name = "Kitchen TH";
          retain = true;
        };
        "0xa4c1383508adae9b" = {
          friendly_name = "Kitchen TRV";
        };
        "0x70b3d52b6013e606" = {
          friendly_name = "Kitchen Plug";
        };
        "0x70b3d52b6010191f" = {
          friendly_name = "Pantry Plug";
        };

        "0xa4c138eeb2a3457b" = {
          friendly_name = "Dining Room TH";
          retain = true;
        };
        "0xa4c138cfac6f68ae" = {
          friendly_name = "Dining Room TRV";
        };

        "0x70b3d52b6013665a" = {
          friendly_name = "Dining Room Plug";
        };

        # Side Lights
        "0xa4c1382e4db54a1f" = {
          friendly_name = "Side Lights";
        };

        # Upstairs Bathroom
        "0xa4c138a74c3c4693" = {
          friendly_name = "Upstairs Bathroom TH";
          retain = true;
        };
        "0xf84477fffe935142" = {
          friendly_name = "Upstairs Bathroom Prox";
        };

        # Downstairs Bathroom
        "0x6cfd22fffe1be062" = {
          friendly_name = "Downstairs Bathroom Prox";
        };

        # Porch
        "0xa4c138a174191ad0" = {
          friendly_name = "Porch Light Switch";
        };
      };
    };
  };
  systemd.services.zigbee2mqtt.serviceConfig.SystemCallFilter = ["@pkey"];

  services.mosquitto = {
    enable = true;
    listeners = [
      {
        address = "0.0.0.0";
        port = 1883;
        users.root = {
          acl = [
            "readwrite #"
          ];
          passwordFile = config.sops.secrets."mosquitto/root".path;
        };
        users.z2m = {
          acl = [
            "readwrite #"
          ];
          passwordFile = config.sops.secrets."mosquitto/z2m".path;
        };
        users.hass = {
          acl = [
            "readwrite #"
          ];
          passwordFile = config.sops.secrets."mosquitto/hass".path;
        };
        users.chimum = {
          acl = [
            "readwrite #"
          ];
          passwordFile = config.sops.secrets."mosquitto/chimum".path;
        };
      }
    ];
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
      "default_config"
      "esphome"
      "met"
      "mqtt"
      "nest"
      "reolink"
      "velux"
      "zha"
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
