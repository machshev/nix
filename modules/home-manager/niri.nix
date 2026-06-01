{
  config,
  pkgs,
  lib,
  ...
}: let
  systemMenu = pkgs.writeShellScript "niri-system-menu" ''
    chosen=$(printf 'Lock\nLogout\nSuspend\nHibernate\nReboot\nShutdown\nUEFI' \
      | ${pkgs.wofi}/bin/wofi --dmenu --prompt "System:")
    case "$chosen" in
      Lock)     ${pkgs.swaylock}/bin/swaylock -f -c 000000 ;;
      Logout)   ${pkgs.niri}/bin/niri msg action quit ;;
      Suspend)  systemctl suspend ;;
      Hibernate) systemctl hibernate ;;
      Reboot)   systemctl reboot ;;
      Shutdown) systemctl poweroff -i ;;
      UEFI)     systemctl reboot --firmware-setup ;;
    esac
  '';
in {
  options.machshev.niri.enable = lib.mkEnableOption "niri wayland compositor";

  config = lib.mkIf config.machshev.niri.enable {
    home.packages = with pkgs; [
      awww
      mako

      blueman
      brightnessctl
      conky
      grim
      maim
      nautilus
      networkmanagerapplet
      pavucontrol
      playerctl
      slurp
      swayidle
      swaylock
      wl-clipboard
      wofi
      xdg-user-dirs
      xdg-utils
      ydotool

      bitwarden-desktop
      bitwarden-cli
      bitwarden-menu
    ];

    # Ensure waybar package is available; sway's waybar module owns style + default config
    programs.waybar.enable = true;

    home.activation.restartWaybarNiri = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if $DRY_RUN_CMD systemctl --user is-active waybar-niri.service > /dev/null 2>&1; then
        $DRY_RUN_CMD systemctl --user restart waybar-niri.service
      fi
    '';

    systemd.user.services.waybar-niri = {
      Unit = {
        Description = "Waybar for niri";
        PartOf = ["niri-session.target"];
        After = ["niri-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.waybar}/bin/waybar --config ${config.xdg.configHome}/waybar/config-niri.json";
        Restart = "on-failure";
      };
      Install.WantedBy = ["niri-session.target"];
    };

    xdg.configFile."waybar/config-niri.json".text = builtins.toJSON {
      position = "bottom";
      height = 24;
      spacing = 8;
      "modules-left" = ["niri/workspaces" "niri/window"];
      "modules-center" = [];
      "modules-right" = [
        "idle_inhibitor"
        "pulseaudio"
        "network"
        "cpu"
        "memory"
        "temperature"
        "backlight"
        "niri/language"
        "battery"
        "clock"
        "tray"
      ];
      "niri/workspaces" = {
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
      "niri/window" = {
        max-length = 60;
      };
      "niri/language" = {
        format = "{short} {variant}";
      };
      "keyboard-state" = {
        numlock = true;
        capslock = true;
        format = "{name} {icon}";
        format-icons = {
          locked = "";
          unlocked = "";
        };
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
        format = "{:%H:%M}";
        format-alt = "{:%Y-%m-%d}";
        tooltip-format = "<big>{:%B %Y}</big>\n<tt><small>{calendar}</small></tt>";
        calendar = {
          mode = "year";
          mode-mon-col = 3;
          weeks-pos = "right";
          on-scroll = 1;
          first-day-of-week = 0;
          format = {
            months = "<span color='#ffead3'><b>{}</b></span>";
            days = "<span color='#ecc6d9'><b>{}</b></span>";
            weeks = "<span color='#99ffdd'><b>W{}</b></span>";
            weekdays = "<span color='#ffcc66'><b>{}</b></span>";
            today = "<span color='#ff6699'><b><u>{}</u></b></span>";
          };
        };
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
    };

    xdg.configFile."niri/config.kdl".text = ''
      input {
        keyboard {
          xkb {
            layout "gb,us,il"
            options "grp:rctrl_toggle"
          }
        }
        touchpad {
          tap
        }
        focus-follows-mouse
      }

      output "BOE 0x0C3F Unknown" {
        position x=1920 y=0
        scale 1.500000
      }

      output "PNP(BNQ) BenQ GL2760 W4G01988019" {
        position x=0 y=0
      }

      output "LG Electronics LG HDR 4K 0x00018916" {
        scale 1.700000
      }

      output "Dell Inc. DELL P3421W 4KF6TR3" {
        scale 1.100000
        position x=-1300 y=-200
      }

      layout {
        gaps 0
        border {
          off
        }
        focus-ring {
          off
        }
      }

      spawn-at-startup "mako"
      spawn-at-startup "nm-applet"
      workspace "1"
      workspace "2"
      workspace "3"
      workspace "4"
      workspace "5"
      workspace "6"
      workspace "7"
      workspace "8"
      workspace "9"

      spawn-at-startup "blueman-applet"
      spawn-at-startup "/run/current-system/sw/libexec/polkit-gnome-authentication-agent-1"
      spawn-at-startup "awww-daemon"
      spawn-at-startup "systemctl" "--user" "restart" "waybar-niri.service"

      binds {
        // Applications
        Mod+T { spawn "alacritty"; }
        Mod+Return { spawn "alacritty"; }
        Mod+N { spawn "firefox"; }
        Mod+X { spawn "bash" "-c" "wofi --modi drun,run --show drun"; }

        Mod+Shift+Slash { show-hotkey-overlay; }

        // Window management
        Mod+Shift+Q { close-window; }
        Mod+F { fullscreen-window; }
        Mod+M { maximize-column; }
        Mod+Shift+F { toggle-window-floating; }

        // Focus
        Mod+H { focus-column-left; }
        Mod+L { focus-column-right; }
        Mod+J { focus-window-down; }
        Mod+K { focus-window-up; }
        Mod+Left { focus-column-left; }
        Mod+Right { focus-column-right; }
        Mod+Down { focus-window-down; }
        Mod+Up { focus-window-up; }

        // Move windows
        Mod+Shift+H { move-column-left; }
        Mod+Shift+L { move-column-right; }
        Mod+Shift+J { move-window-down; }
        Mod+Shift+K { move-window-up; }
        Mod+Shift+Left { move-column-left; }
        Mod+Shift+Right { move-column-right; }
        Mod+Shift+Down { move-window-down; }
        Mod+Shift+Up { move-window-up; }

        // Workspaces
        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }
        Mod+Shift+1 { move-column-to-workspace 1; }
        Mod+Shift+2 { move-column-to-workspace 2; }
        Mod+Shift+3 { move-column-to-workspace 3; }
        Mod+Shift+4 { move-column-to-workspace 4; }
        Mod+Shift+5 { move-column-to-workspace 5; }
        Mod+Shift+6 { move-column-to-workspace 6; }
        Mod+Shift+7 { move-column-to-workspace 7; }
        Mod+Shift+8 { move-column-to-workspace 8; }
        Mod+Shift+9 { move-column-to-workspace 9; }

        // Move workspace to output
        Mod+Ctrl+Shift+Right { move-workspace-to-monitor-right; }
        Mod+Ctrl+Shift+Left { move-workspace-to-monitor-left; }
        Mod+Ctrl+Shift+Down { move-workspace-to-monitor-down; }
        Mod+Ctrl+Shift+Up { move-workspace-to-monitor-up; }

        // Media
        XF86AudioLowerVolume { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-" "-l" "1.2"; }
        XF86AudioRaiseVolume { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+" "-l" "1.2"; }
        XF86AudioMute { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
        XF86AudioMicMute { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }
        XF86MonBrightnessUp { spawn "brightnessctl" "s" "10%+"; }
        XF86MonBrightnessDown { spawn "brightnessctl" "s" "10%-"; }
        XF86AudioPlay { spawn "playerctl" "play-pause"; }
        XF86AudioNext { spawn "playerctl" "next"; }
        XF86AudioPrev { spawn "playerctl" "previous"; }
        Mod+F5 { spawn "brightnessctl" "s" "10%-"; }
        Mod+F6 { spawn "brightnessctl" "s" "10%+"; }

        // Notifications
        Mod+Ctrl+Space { spawn "makoctl" "dismiss"; }
        Mod+Ctrl+Shift+Space { spawn "makoctl" "dismiss" "--all"; }

        // Screenshots (save to file)
        Ctrl+Print { spawn "bash" "-c" "grim $(xdg-user-dir PICTURES)/$(date +'%s_screenshot.png')"; }
        Ctrl+Super+Print { screenshot-screen; }
        Ctrl+Shift+Print { spawn "bash" "-c" "grim -g \"$(slurp)\" $(xdg-user-dir PICTURES)/$(date +'%s_screenshot.png')"; }

        // Screenshots (copy to clipboard)
        Print { spawn "bash" "-c" "grim - | wl-copy"; }
        Super+Print { screenshot-window; }
        Shift+Print { spawn "bash" "-c" "grim -g \"$(slurp)\" - | wl-copy"; }

        // System
        Mod+Shift+C { spawn "niri" "msg" "action" "load-config-file"; }
        Mod+Shift+Period { spawn "systemctl" "suspend"; }
        Mod+Ctrl+L { spawn "swaylock" "-f" "-c" "000000"; }
        Mod+Shift+E { spawn "${systemMenu}"; }
      }
    '';
  };
}
