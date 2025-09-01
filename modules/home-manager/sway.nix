{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./waybar
  ];

  home.packages = with pkgs; [
    nitrogen
    mako

    blueman
    brightnessctl
    dunst
    nautilus
    grim
    pavucontrol
    playerctl
    slurp
    swayidle
    swaylock
    wl-clipboard
    wofi
    xclip
    xdg-desktop-portal-gtk
    xdg-desktop-portal-wlr
    xdg-user-dirs
    xdg-utils
    ydotool

    bitwarden-desktop
    bitwarden-cli
    bitwarden-menu
    goldwarden
  ];

  wayland.windowManager.sway = let
    mode_system = "System: (l)ock, (e) logout, (s)uspend, (h)ibernate, (r)eboot, (S)hutdown, (R) UEFI";
    lock = "swaylock -f -c 000000";
    mode_default = "mode \"default\"";
  in {
    enable = true;
    config = rec {
      modifier = "Mod4";

      terminal = "alacritty";
      menu = "dmenu_path | dmenu | xargs swaymsg exec --";

      window = {
        hideEdgeBorders = "smart";
        titlebar = false;
        border = 0;
      };

      floating = {
        titlebar = false;
        border = 0;
      };

      keybindings = lib.mkOptionDefault {
        "${modifier}+n" = "exec firefox";
        "${modifier}+t" = "exec cosmic-term";
        "${modifier}+x" = "exec 'wofi --modi drun,run --show drun'";

        # Move workspace
        "${modifier}+Ctrl+Shift+Right" = "move workspace to output right";
        "${modifier}+Ctrl+Shift+Left" = "move workspace to output left";
        "${modifier}+Ctrl+Shift+Down" = "move workspace to output down";
        "${modifier}+Ctrl+Shift+Up" = "move workspace to output up";

        # Media buttons
        "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- -l 1.2";
        "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ -l 1.2";
        "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        "XF86AudioMicMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
        "XF86MonBrightnessUp" = "exec brightnessctl s 10%+";
        "XF86MonBrightnessDown" = "exec brightnessctl s 10%-";
        "XF86AudioPlay" = "exec playerctl play-pause";
        "XF86AudioNext" = "exec playerctl next";
        "XF86AudioPrev" = "exec playerctl previous";
        "${modifier}+f5" = "exec brightnessctl s 10%-";
        "${modifier}+f6" = "exec brightnessctl s 10%+";

        # Notifications
        "${modifier}+Ctrl+Space" = "exec makoctl dismiss";
        "${modifier}+Ctrl+Shift+Space" = "exec makoctl dismiss --all";

        ## Screenshots
        "Ctrl+Print" = "exec grim $(xdg-user-dir PICTURES)/$(date +'%s_screenshot.png')";
        "Ctrl+${modifier}+Print" = "exec grim -g \"$(swaymsg -t get_tree | jq -j '.. | select(.type?) | select(.focused).rect | \"\(.x),\(.y) \(.width)x\(.height)\"')\" $(xdg-user-dir PICTURES)/$(date +'%s_screenshot.png')";
        "Ctrl+Shift+Print" = "exec grim -g \"$(slurp)\" $(xdg-user-dir PICTURES)/$(date +'%s_screenshot.png')";

        ## Clipboard Screenshots
        "Print" = "exec grim - | wl-copy";
        "${modifier}+Print" = "exec grim -g \"$(swaymsg -t get_tree | jq -j '.. | select(.type?) | select(.focused).rect | \"\(.x),\(.y) \(.width)x\(.height)\"')\" - | wl-copy";
        "Shift+Print" = "exec grim -g \"$(slurp)\" - | wl-copy";

        # Suspend
        "${modifier}+Shift+period" = "exec systemctl suspend";
        "${modifier}+Shift+e" = "mode \"${mode_system}\"";
      };

      modes = lib.mkOptionDefault {
        "${mode_system}" = {
          l = "exec ${lock}, ${mode_default}";
          e = "exit";
          s = "exec --no-startup-id systemctl suspend, ${mode_default}";
          h = "exec --no-startup-id systemctl hibernate, ${mode_default}";
          r = "exec --no-startup-id systemctl reboot, ${mode_default}";
          "Shift+s" = "exec --no-startup-id systemctl poweroff -i, ${mode_default}";
          "Shift+r" = "exec --no-startup-id systemctl reboot --firmware-setup, ${mode_default}";

          # return to default mode
          Return = "${mode_default}";
          Escape = "${mode_default}";
        };
      };

      input = {
        "1:1:AT_Translated_Set_2_keyboard" = {
          xkb_layout = "gb";
        };

        "7247:21:SIGMACH1P_USB_Keyboard" = {
          xkb_layout = "gb";
        };

        "1118:2040:Microsoft_Wired_Keyboard_600" = {
          xkb_layout = "gb";
        };

        "16700:8467:Dell_KB216_Wired_Keyboard" = {
          xkb_layout = "us,il";
          xkb_options = "grp:rctrl_toggle";
        };
      };

      output = {
        "BOE 0x0C3F Unknown" = {
          pos = "1920 0";
          scale = "1.5";
        };

        "BNQ BenQ GL2760 W4G01988019" = {
          pos = "0 0";
        };

        "LG Electronics LG HDR 4K 0x00018916" = {
          scale = "1.7";
        };

        "Dell Inc. DELL P3421W 4KF6TR3" = {
          scale = "1.1";
          pos = "-1300 -200";
        };
      };

      bars = [
        {
          command = "${pkgs.waybar}/bin/waybar";
          position = "bottom";
          #height = 25;
          #spacing = 8;
        }
      ];

      startup = [
        {command = "mako";}
        {command = "nm-applet";}
        {command = "blueman-applet &";}
        {command = "/run/current-system/sw/libexec/polkit-gnome-authentication-agent-1 &";}
        {
          command = "nitrogen --restore";
          always = true;
        }
      ];
    };
  };
}
