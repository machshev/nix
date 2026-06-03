{
  pkgs,
  lib,
  isDesktop ? false,
  ...
}: {
  imports =
    [
      ../bash.nix
      ../dev.nix
      ../fish.nix
      ../starship
      ../term.nix
    ]
    ++ lib.optionals isDesktop [
      ../ai.nix
      ../internet.nix
      ../sway.nix
    ];

  home.stateVersion = "24.11"; # Please read the comment before changing.

  dconf.settings = lib.mkIf isDesktop {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };

  home.file = {};

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.packages =
    (with pkgs; [taskwarrior3])
    ++ lib.optionals isDesktop (with pkgs; [cheese]);

  programs.git = {
    enable = true;
    settings.user = {
      email = "djmccorrie@gmail.com";
      name = "David James McCorrie";
      # signing.key = "GPG-KEY-ID";
      # signing.signByDefault = true;
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
