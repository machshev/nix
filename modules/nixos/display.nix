{
  config,
  pkgs,
  lib,
  ...
}:
with lib; {
  options = {
    machshev.display = mkOption {
      type = types.bool;
      default = true;
      description = "Enable display.";
    };
    machshev.vulkan = mkOption {
      type = types.bool;
      default = true;
      description = "Enable vulkan.";
    };
  };

  config = mkIf config.machshev.display {
    xdg.icons.enable = true;
    xdg.mime.enable = true;

    xdg.mime.defaultApplications = {
      "text/html" = "firefox";
      "x-scheme-handler/http" = "firefox";
      "x-scheme-handler/https" = "firefox";
      "x-scheme-handler/about" = "firefox";
      "x-scheme-handler/unknown" = "firefox";
    };

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      config = {
        sway = {
          default = ["gtk"];
          "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
          "org.freedesktop.portal.ScreenCast" = ["wlr"];
          "org.freedesktop.portal.Screenshot" = ["wlr"];
          "org.freedesktop.portal.OpenURI" = ["gtk"];
        };
      };
      xdgOpenUsePortal = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-wlr
        pkgs.xdg-desktop-portal-gtk
      ];
    };

    # Gnome (required for gtk portal)
    services.xserver.enable = true;
    services.displayManager.gdm.enable = true;
    services.displayManager.gdm.wayland = true;
    services.desktopManager.gnome.enable = true;

    services.gnome.core-apps.enable = false;
    services.gnome.core-developer-tools.enable = false;
    services.gnome.games.enable = false;
    environment.gnome.excludePackages = with pkgs; [gnome-tour gnome-user-docs];

    # Sway
    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
    };

    services.dbus.enable = true;

    environment.systemPackages = with pkgs;
      lib.mkMerge [
        [
          xdg-desktop-portal-gtk
          xdg-desktop-portal-wlr
          wlroots
          xwayland
          wlr-randr
          qt5.qtwayland
          qt6.qmake
          qt6.qtwayland
          adwaita-qt
          adwaita-fonts
          adwaita-icon-theme
        ]
        (mkIf config.machshev.vulkan [
          vulkan-tools
          vulkan-validation-layers
          vulkan-loader
          vulkan-tools-lunarg
        ])
      ];

    qt = {
      enable = true;
      # platformTheme = "gnome";
      #style = "adwaita-dark";
    };

    environment.sessionVariables = lib.mkMerge [
      {
        CLUTTER_BACKEND = "wayland";
        GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";
        GTK_USE_PORTAL = "1";
        MOZ_ENABLE_WAYLAND = "1";
        NIXOS_OZONE_WL = "1";
        NIXOS_XDG_OPEN_USE_PORTAL = "1";
        POLKIT_AUTH_AGENT = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        SDL_VIDEODRIVER = "wayland";
        WLR_NO_HARDWARE_CURSORS = "1";
        XDG_CURRENT_DESKTOP = "sway";
        XDG_SESSION_DESKTOP = "sway";
        XDG_SESSION_TYPE = "wayland";
        _JAVA_AWT_WM_NONREPARENTING = "1";
      }
      (mkIf config.machshev.vulkan {
        WLR_RENDERER = "vulkan";
      })
    ];
  };
}
