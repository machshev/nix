{
  config,
  lib,
  ...
}:
with lib; {
  options = {
    machshev.printing = mkOption {
      type = types.bool;
      default = true;
      description = "Enable printing services.";
    };
  };

  config = mkIf config.machshev.printing {
    services.printing = {
      enable = true;
      browsing = true;
      defaultShared = true;
    };
  };
}
