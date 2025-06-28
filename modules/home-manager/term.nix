{pkgs, ...}: {
  home.packages = with pkgs; [
    nnn
    screen
    tmux

    cosmic-term

    # system
    gparted

    # installing and syncing
    stow
    rclone

    # ssh and remote
    mosh
    wget
    curl
    wayvnc

    # editors and viewing
    neovim

    # git
    gitui

    # docs
    tealdeer

    # archives
    unzip
    xz
    p7zip
    zip

    # networking
    mtr
    bandwhich
    iperf3
    dnsutils
    ldns
    aria2
    socat
    nmap
    ipcalc
  ];

  programs.alacritty = {
    enable = true;
    settings = {
      env = {
        "TERM" = "xterm-256color";
      };

      window = {
        padding.x = 0;
        padding.y = 0;
        decorations = "buttonless";
      };

      font = {
        size = 8.0;

        normal.family = "Hack Nerd Font";
        bold.family = "Hack Nerd Font";
        italic.family = "Hack Nerd Font";
      };

      cursor.style = "Beam";

      terminal.shell = {
        program = "fish";
      };

      colors = {
        # Default colors
        primary = {
          background = "0x000000";
          foreground = "0xffffff";
        };

        # Normal colors
        normal = {
          black = "0x000000";
          blue = "0x4040ee";
          cyan = "0x00cdcd";
          green = "0x00cd00";
          magenta = "0xcd00cd";
          red = "0xcd0000";
          white = "0xe5e5e5";
          yellow = "0xcdcd00";
        };

        # Bright colors
        bright = {
          black = "0x7f7f7f";
          blue = "0x7070ff";
          cyan = "0x00ffff";
          green = "0x00ff00";
          magenta = "0xff00ff";
          red = "0xff0000";
          white = "0xffffff";
          yellow = "0xffff00";
        };
      };

      keyboard.bindings = [
        {
          chars = "\u001B[1;6P";
          key = "Key1";
          mods = "Control";
        }
        {
          chars = "\u001B[1;6Q";
          key = "Key2";
          mods = "Control";
        }
        {
          chars = "\u001B[1;6R";
          key = "Key3";
          mods = "Control";
        }
        {
          chars = "\u001B[1;6S";
          key = "Key4";
          mods = "Control";
        }
        {
          chars = "\u001B[15;6~";
          key = "Key5";
          mods = "Control";
        }
        {
          chars = "\u001B[17;6~";
          key = "Key6";
          mods = "Control";
        }
        {
          chars = "\u001B[18;6~";
          key = "Key7";
          mods = "Control";
        }
        {
          chars = "\u001B[19;6~";
          key = "Key8";
          mods = "Control";
        }
        {
          chars = "\u001B[20;6~";
          key = "Key9";
          mods = "Control";
        }
        {
          chars = "\u001B[21;6~";
          key = "Key0";
          mods = "Control";
        }
      ];
    };
  };
}
