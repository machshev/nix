{
  nixpkgs,
  nixpkgs-unstable,
  flake-utils,
  ...
}:
flake-utils.lib.eachDefaultSystemMap (system: let
  pkgs = import nixpkgs {
    inherit system;
  };
  pkgs-unstable = import nixpkgs-unstable {
    inherit system;
  };
  mb7ujmBinfmt =
    if system == "x86_64-linux"
    then let
      binfmtSystem = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          {
            boot.binfmt = {
              emulatedSystems = ["aarch64-linux"];
              preferStaticEmulators = true;
            };
            system.stateVersion = "26.05";
          }
        ];
      };
      registration = binfmtSystem.config.boot.binfmt.registrations."aarch64-linux";
      registrationFile = pkgs.runCommand "mb7ujm-aarch64-binfmt.conf" {} ''
        substitute \
          ${binfmtSystem.config.environment.etc."binfmt.d/nixos.conf".source} \
          "$out" \
          --replace-fail ":aarch64-linux:" ":mb7ujm-aarch64:" \
          --replace-fail "/run/binfmt/aarch64-linux" "/run/binfmt/mb7ujm-aarch64"
      '';
      enable = pkgs.writeShellApplication {
        name = "mb7ujm-enable-binfmt";
        runtimeInputs = with pkgs; [
          coreutils
          util-linux
        ];
        text = ''
          registration=/proc/sys/fs/binfmt_misc/mb7ujm-aarch64

          if [ -e "$registration" ]; then
            echo "MB7UJM aarch64 binfmt registration is already active."
            exit 0
          fi

          if ! mountpoint -q /proc/sys/fs/binfmt_misc; then
            sudo mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
          fi

          sudo install -d --mode=0755 /run/binfmt
          sudo ln -sfn ${registration.interpreter} /run/binfmt/mb7ujm-aarch64
          sudo ${pkgs.bash}/bin/bash -c \
            'cat "$1" > /proc/sys/fs/binfmt_misc/register' \
            mb7ujm-binfmt ${registrationFile}

          if [ ! -e "$registration" ]; then
            echo "Failed to register the aarch64 interpreter." >&2
            exit 1
          fi

          echo "MB7UJM aarch64 binfmt registration enabled until cleanup or reboot."
        '';
      };
      disable = pkgs.writeShellApplication {
        name = "mb7ujm-disable-binfmt";
        runtimeInputs = [pkgs.coreutils];
        text = ''
          registration=/proc/sys/fs/binfmt_misc/mb7ujm-aarch64

          if [ -e "$registration" ]; then
            printf '%s\n' -1 | sudo ${pkgs.coreutils}/bin/tee "$registration" >/dev/null
          fi
          sudo rm -f /run/binfmt/mb7ujm-aarch64

          echo "MB7UJM aarch64 binfmt registration disabled."
        '';
      };
    in {
      packages = [
        enable
        disable
      ];
      buildOption = "--option extra-platforms aarch64-linux";
      instructions = ''
        Run mb7ujm-enable-binfmt once before building.
        Run mb7ujm-disable-binfmt afterwards if you want to remove it immediately.
      '';
    }
    else {
      packages = [];
      buildOption = "";
      instructions = "Native aarch64 build; no binfmt registration is needed.";
    };
  mb7ujmBuildImage = pkgs.writeShellApplication {
    name = "mb7ujm-build-image";
    runtimeInputs = [pkgs.nix];
    text = ''
      ${
        if system == "x86_64-linux"
        then ''
          if [ ! -e /proc/sys/fs/binfmt_misc/mb7ujm-aarch64 ] \
            && [ ! -e /proc/sys/fs/binfmt_misc/aarch64-linux ] \
            && [ ! -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ]; then
            echo "No aarch64 binfmt registration is active." >&2
            echo "Run mb7ujm-enable-binfmt first." >&2
            exit 1
          fi
        ''
        else ""
      }
      exec nix build \
        ${mb7ujmBinfmt.buildOption} \
        "$@" \
        path:.#nixosConfigurations.mb7ujm.config.system.build.sdImage
    '';
  };
  mb7ujmProvisionWifi = pkgs.writeShellApplication {
    name = "mb7ujm-provision-wifi";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.networkmanager
      pkgs.sudo
      pkgs.util-linux
    ];
    text = ''
      if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
        echo "Usage: mb7ujm-provision-wifi /path/to/NIXOS_SD [NM_CONNECTION]" >&2
        exit 2
      fi

      root_mount=$1
      destination=$root_mount/etc/NetworkManager/system-connections/mb7ujm-wifi.nmconnection

      root_label=$(findmnt --noheadings --output LABEL --target "$root_mount" | tr -d '[:space:]')
      if [ ! -d "$root_mount" ] || [ "$root_label" != NIXOS_SD ]; then
        echo "$root_mount is not the MB7UJM NIXOS_SD partition." >&2
        exit 1
      fi

      profile=$(mktemp)
      cleanup() {
        rm -f -- "$profile"
      }
      trap cleanup EXIT

      if [ "$#" -eq 2 ]; then
        connection_name=$2
      else
        connection_name=
        while IFS= read -r candidate; do
          [ -n "$candidate" ] || continue
          connection_type=$(
            nmcli --get-values connection.type connection show "$candidate"
          )
          if [ "$connection_type" = "802-11-wireless" ]; then
            if [ -n "$connection_name" ]; then
              echo "More than one Wi-Fi connection is active; specify its name." >&2
              exit 1
            fi
            connection_name=$candidate
          fi
        done < <(nmcli --get-values NAME connection show --active)
      fi

      if [ -z "$connection_name" ]; then
        echo "No active Wi-Fi connection found; specify a connection name." >&2
        exit 1
      fi

      ssid=$(
        nmcli --show-secrets \
          --get-values 802-11-wireless.ssid \
          connection show "$connection_name"
      )
      psk=$(
        nmcli --show-secrets \
          --get-values 802-11-wireless-security.psk \
          connection show "$connection_name"
      )

      if [ -z "$ssid" ] || [ -z "$psk" ]; then
        echo "Could not read an SSID and WPA-PSK from '$connection_name'." >&2
        echo "The profile must store its PSK in NetworkManager." >&2
        exit 1
      fi

      nmcli --offline connection add \
        type wifi \
        con-name mb7ujm-wifi \
        ssid "$ssid" \
        wifi-sec.key-mgmt wpa-psk \
        wifi-sec.psk "$psk" \
        >"$profile"
      sudo install -D --mode=0600 "$profile" "$destination"
      sync "$root_mount"

      echo "Provisioned Wi-Fi connection '$connection_name' onto NIXOS_SD."
    '';
  };
in {
  admin = pkgs.mkShell {
    name = "Administration";
    packages =
      (with pkgs; [
        ssh-to-age
        rage
        yubikey-manager
        age-plugin-yubikey
        gparted
      ])
      ++ (with pkgs-unstable; [
        sops
      ]);
  };

  embedded = pkgs.mkShell {
    name = "Embedded dev shell";
    packages = with pkgs; [
      screen
    ];
  };

  mb7ujm = pkgs.mkShell {
    name = "MB7UJM SD image builder";
    packages =
      [
        mb7ujmBuildImage
        mb7ujmProvisionWifi
        pkgs.zstd
      ]
      ++ mb7ujmBinfmt.packages;
    shellHook = ''
      echo "MB7UJM SD image build shell"
      echo "${mb7ujmBinfmt.instructions}"
      echo "Build with: mb7ujm-build-image"
      echo "Provision with: mb7ujm-provision-wifi /path/to/NIXOS_SD [NM_CONNECTION]"
    '';
  };

  re-hacking = pkgs.mkShell {
    name = "Reverse Engineering";
    packages = with pkgs; [
      binwalk
      teehee
      ghidra
      radare2
      cutter
    ];
  };

  hardware-hacking = pkgs.mkShell {
    name = "Hardware Hacking";
    packages = with pkgs; [
      sigrok-cli
      sigrok-firmware-fx2lafw
      pulseview
      picotool
    ];
  };

  rust = pkgs.mkShell {
    name = "Rust dev shell";
    packages = with pkgs; [
      rustc
      rust-analyzer
      cargo
      evcxr
    ];
  };

  go = pkgs.mkShell {
    name = "Go dev shell";
    packages = with pkgs; [
      go
      gopls
      buf
    ];
  };

  python = pkgs.mkShell {
    name = "Python dev shell";
    packages =
      (with pkgs; [
        uv
        ruff
        ty
        pyright
        python313
        python313Packages.ipython
      ])
      ++ (with pkgs-unstable; [
        pyrefly
      ]);
  };

  zig = pkgs.mkShell {
    name = "Zig dev shell";
    packages = with pkgs; [
      zig
      zls
    ];
  };

  js = pkgs.mkShell {
    name = "JS/Node dev shell";
    packages = with pkgs; [
      nodejs
    ];
  };

  wasm = pkgs.mkShell {
    name = "WASM dev shell";
    packages = with pkgs; [
      wabt
      asm-lsp
    ];
  };

  lua = pkgs.mkShell {
    name = "Lua dev shell";
    packages = with pkgs; [
      lua-language-server
      stylua
    ];
  };

  tf = pkgs.mkShell {
    name = "terraform dev shell";
    packages = with pkgs; [
      opentofu
      terraform-ls # opentofu-ls not yet included
      google-cloud-sdk
      yamllint
      yaml-language-server
      yq
      jq
    ];
  };

  ans = pkgs.mkShell {
    name = "Ansible dev shell";
    packages = with pkgs; [
      ansible-lint
    ];
  };

  net = pkgs.mkShell {
    name = "Networking dev shell";
    packages = with pkgs; [
      wireshark
      nmap
      lrzsz
    ];
  };
})
