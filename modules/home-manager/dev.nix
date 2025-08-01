{pkgs, ...}: {
  home.packages = with pkgs; [
    # Common
    direnv
    gh
    git
    git-interactive-rebase-tool
    gnumake
    teehee
    tokei
    typos-lsp

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

    # Rust
    evcxr # rust repl


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
