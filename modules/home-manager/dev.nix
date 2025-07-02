{pkgs, ...}: {
  home.packages = with pkgs; [
    # Common
    gnumake
    git
    git-interactive-rebase-tool
    typos-lsp
    gh
    direnv
    tokei

    # Asm
    asm-lsp

    # WASM
    wabt

    # Zig
    zig
    zls

    # C
    gcc
    #clang
    maim
    conky

    # Nix
    nil

    # Node
    nodejs

    # Shell
    shellcheck
    shfmt
    nodePackages.bash-language-server

    # Docker
    docker-compose

    # libvirt
    virt-manager

    # eda
    usbutils

    # Programmers
    #segger-ozone
    openssl.dev

    # Misc [old]
    v4l-utils
    vlc
  ];
}
