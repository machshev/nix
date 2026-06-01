{
  pkgs,
  lib,
  isDesktop ? false,
  ...
}: {
  home.packages =
    (with pkgs; [
    # Common
    direnv
    gh
    git
    git-interactive-rebase-tool
    gnumake
    tokei

    # Common lsp
    typos-lsp
    nil # nix
    bash-language-server

    # C
    gcc

    # Shell
    shellcheck
    shfmt

    # Docker
    docker-compose

    # eda
    usbutils
  ])
  ++ lib.optionals isDesktop (with pkgs; [
    # libvirt
    virt-manager
  ]);
}
