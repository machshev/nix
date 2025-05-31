{
  nixpkgs,
  flake-utils,
  ...
}: flake-utils.lib.eachDefaultSystemMap (system: let
  pkgs = import nixpkgs {
    inherit system;
  };
in  {
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
    ];
  };

  go = pkgs.mkShell {
    name = "Go dev shell";
    packages = with pkgs; [
      go
      buf
    ];
  };

  python = pkgs.mkShell {
    name = "Python dev shell";
    packages = with pkgs; [
      uv
      ruff
      pyright
      python313
      python313Packages.ipython
    ];
  };

  lua = pkgs.mkShell {
    name = "Lua dev shell";
    packages = with pkgs; [
      lua-language-server
      stylua
    ];
  };

  tf = pkgs.mkshell {
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

  ans = pkgs.mkshell {
    name = "Ansible dev shell";
    packages = with pkgs; [
      ansible-language-server
      ansible-lint
    ];
  };

  net = pkgs.mkShell {
    name = "Networking dev shell";
    packages = with pkgs; [
      wireshark
      nmap
    ];
  };
})
