{pkgs, pkgs-unstable, ...}: {
  home.packages = (with pkgs; [
    # Common
    direnv
    gh
    git
    git-interactive-rebase-tool
    gnumake
    teehee
    tokei

    # Common lsp
    typos-lsp
    yamllint
    yaml-language-server
    terraform-ls # opentofu-ls not yet included
    asm-lsp
    zls # zig
    nil # nix
    nodePackages.bash-language-server

    # WASM
    wabt

    # Zig
    zig

    # C
    gcc
    maim
    conky

    # Rust
    evcxr # rust repl

    # Python
    ruff
    pyright

    # Node
    nodejs

    # Shell
    shellcheck
    shfmt

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
  ]) ++ (with pkgs-unstable; [
    # Python
    python313Packages.pyrefly
  ]);
}
