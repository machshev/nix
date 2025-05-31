{
  lib,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    libreoffice
  ];
}
