{
  pkgs,
  user-helpers,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  machshev = {
    hostName = "anan";
    machineID = "1c4c095a3728942bbc73011192e82ead";
    autoupdate.enable = false;
    graphics.enable = false;
    display = false;
    sound = false;
    vps = true;
    server = true;
  };

  users.users.david = user-helpers.mkUserCfg {
    inherit pkgs;
    name = "david";
  };

  system.stateVersion = "24.11";
}
