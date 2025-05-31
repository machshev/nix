{pkgs, ...}: {
  programs.waybar = {
    enable = true;
    style = builtins.readFile ./style.css;
    settings = [
      {
        position = "bottom";
        height = 25;
        spacing = 8;
        modules-left = ["sway/workspaces" "sway/mode" "sway/scratchpad" "custom/media"];
        modules-center = ["sway/window"];
        modules-right = [
          "idle_inhibitor"
          "pulseaudio"
          "network"
          "cpu"
          "memory"
          "temperature"
          "backlight"
          "keyboard-state"
          "sway/language"
          "battery"
          "battery#bat2"
          "clock"
          "tray"
        ];

        # Modules configuration

        "sway/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
          warp-on-scroll = false;
          format = "{name}";
          format-icons = {
            "1" = "";
            "2" = "";
            "3" = "";
            "4" = "";
            "5" = "";
            urgent = "";
            focused = "";
            default = "";
          };
        };
        keyboard-state = {
          numlock = true;
          capslock = true;
          format = "{name} {icon}";
          format-icons = {
            locked = "";
            unlocked = "";
          };
        };
        "sway/mode" = {
          format = "<span style=\"italic\">{}</span>";
        };
        "sway/scratchpad" = {
          format = "{icon} {count}";
          show-empty = false;
          format-icons = ["" ""];
          tooltip = true;
          tooltip-format = "{app} = {title}";
        };
        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            deactivated = "😴";
            activated = "😵‍💫";
          };
        };
        tray = {
          icon-size = "21";
          spacing = "10";
        };
        clock = {
          tooltip-format = "<big>{ =%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          format-alt = "{ =%Y-%m-%d}";
        };
        cpu = {
          format = "{usage}%";
          tooltip = false;
        };
        memory = {
          format = "M ={}%";
        };
        temperature = {
          critical-threshold = "80";
          format = "{temperatureC}°C";
          format-icons = ["" "" ""];
        };
        backlight = {
          format = "{percent}% {icon}";
          format-icons = ["" "" "" "" "" "" "" "" ""];
        };
        battery = {
          states = {
            warning = "30";
            critical = "15";
          };
          format = "{capacity}% {icon}";
          format-full = "{capacity}% {icon}";
          format-charging = "{capacity}% ";
          format-plugged = "{capacity}% ";
          format-alt = "{time} {icon}";
          format-icons = ["" "" "" "" ""];
        };
        "battery#bat2" = {
          bat = "BAT2";
        };
        network = {
          format-wifi = "{essid} ({signalStrength}%)";
          format-ethernet = "{ipaddr}/{cidr}";
          tooltip-format = "{ifname} via {gwaddr}";
          format-linked = "{ifname} (No IP)";
          format-disconnected = "Disconnected";
          format-alt = "{ifname} = {ipaddr}/{cidr}";
        };
        pulseaudio = {
          format = "{volume}% {icon} {format_source}";
          format-bluetooth = "{volume}% {icon}{format_source}";
          format-bluetooth-muted = "m {icon}{format_source}";
          format-muted = "m {format_source}";
          format-source = "{volume}%";
          format-source-muted = "m";
          format-icons = {
            headphone = "h";
            hands-free = "hf";
            headset = "H";
            phone = "P";
            portable = "p";
            car = "C";
            default = ["a" "b" "c"];
          };
          on-click = "pavucontrol";
        };
        "sway/language" = {
          format = "{short} {variant}";
          on-click = "swaymsg input type =keyboard xkb_switch_layout next";
        };
      }
    ];
  };
}
