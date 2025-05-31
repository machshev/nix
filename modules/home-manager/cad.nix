{pkgs, ...}: {
  home.packages = with pkgs; [
    inkscape
    gimp

    freecad
    blender

    kicad
  ];
}
