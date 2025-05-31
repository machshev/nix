{
  inputs,
  pkgs,
  pkgs-unstable,
  user-helpers,
  lib,
  ...
}: {
  imports = [
    # ./fs.nix # migrate to disko if reformatting at some point
    ./hardware-configuration.nix

    {config.facter.reportPath = ./facter.json;}
    inputs.nixos-facter-modules.nixosModules.facter
    inputs.lowrisc-it.nixosModules.lowrisc
  ];

  machshev = {
    hostName = "avodah";
    machineID = "50056b9ffefaf919166d579d676a9115";
    applyUdevRules = true;
    autoupdate = {
      enable = false;
    };
    closedFirmwareUpdates = true;
    networkWait = false;
    graphics = {
      enable = true;
      intel = true;
    };
  };

  lowrisc = {
    identity = "james.mccorrie@lowrisc.org";
    auth.gcloudCli = {
      enable = true;
      user = "jamesm";
    };
    configSync.enable = true;
    network = true;
    tools.enable = true;
    nixRegistry.enable = true;
    usePublicCache = true;
    applyUdevRules = true;
    faillock.enable = true;
    nebula.enable = true;
  };

  users.users.jamesm = user-helpers.mkUserCfg {
    inherit pkgs;
    name = "jamesm";
  };

  home-manager = user-helpers.mkHomeManager {
    inherit inputs;
    users = ["jamesm"];
  };

  services.printing.drivers = [pkgs.hplip];

  services.clamav = {
    daemon.enable = true;
    updater.enable = true;
    clamonacc.enable = true;

    daemon.settings = {
      DetectPUA = true;
      OnAccessPrevention = true;
      OnAccessExtraScanning = true;
      OnAccessIncludePath = "/home/jamesm/Downloads";
    };
  };

  system.autoUpgrade = {
    enable = true;
    flake = inputs.self.outPath;
    flags = [
      "--update-input"
      "nixpkgs"
      "--commit-lock-file"
      "-L" # print build logs
    ];
    dates = "02:00";
    randomizedDelaySec = "45min";
  };

  nixpkgs.config.allowUnfree = true;
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = ["jamesm"];
  };

  environment.systemPackages =
    (with pkgs; [
      pam_u2f
      yubikey-manager
      age-plugin-yubikey
      calibre
    ])
    ++ (with pkgs-unstable; [
      sops
    ]);

  security.pam.u2f = {
    enable = true;
    settings = {
      origin = "pam://localhost";
      cue = true;
      pinverification = 1;
      authfile = pkgs.writeText "u2f_keys" ''
        jamesm:UecSnWDSAMaoK3UWMcypYgOe5m6Ev0mDk4rMjI6jhWpIKFG0iXhM0hoOZE8xphiLJfR99ko2fNELx4/eysJ2lQ==,B7+dCFExwu7pA3/WUOb2hHZn3hTBJXtWbbAR87zJ/3phAWMd6OebApBeWZ2kryf7zWLrsnyVqntflPHY7lNJ3g==,es256,+presence:GmiImXHt5/aCrWi0vRjAKSS0zbuioJuwe8urks2mYV9/tnCFMVIwNzwAyJCu2XTfQQI/34c+odR1ZWtFnLVxEA==,wdzHy7/T+KrGgqurMJHhwpfylIqHFOye57rJwlqeT4oVdU/qHrYAM7JyPPLA0QcayL8yTa8x15N35RWsqhzh0Q==,es256,+presence
      '';
    };
  };

  # Enable u2f sudo authentication and prevent password sudo
  security.pam.services.sudo.u2fAuth = true;
  security.pam.services.sudo.unixAuth = false;
  security.pam.services.polkit-1.u2fAuth = true;
  security.pam.services.polkit-1.unixAuth = false;

  services.pcscd.enable = true;

  systemd.services.NetworkManager-wait-online.enable = false;
  systemd.network.wait-online.anyInterface = true;
  systemd.network.networks."50-enp0s" = {
    matchConfig.Name = "enp0s";
    # acquire a DHCP lease on link up
    networkConfig.DHCP = "yes";
    # this port is not always connected and not required to be online
    linkConfig.RequiredForOnline = "no";
  };

  system.stateVersion = "24.11";
}
