{
  lib,
  pkgs,
  ...
}: {
  imports = [
    # ../cad.nix
    ../dev.nix
    ../fish.nix
    ../internet.nix
    #./office.nix
    ../starship
    ../sway.nix
    ../term.nix
    ../nixvim.nix
  ];

  home.stateVersion = "24.11"; # Please read the comment before changing.

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
  ];

  programs.git = {
    enable = true;
    settings.user = {
      email = "joseph.mccorrie@gmail.com";
      name = "Joseph McCorrie";
      # signing.key = "GPG-KEY-ID";
      # signing.signByDefault = true;
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
