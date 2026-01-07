{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options = {
    machshev.printing = mkOption {
      type = types.bool;
      default = false;
      description = "Enable printing services.";
    };
  };

  config = mkIf config.machshev.printing {
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    services.printing = {
      enable = true;
      browsing = true;
      defaultShared = true;
      drivers = with pkgs; [
        cups-filters
        cups-browsed
        hplip
      ];
    };
  };
}
