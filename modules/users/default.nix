{lib}: {
  mkUserCfg = {
    pkgs,
    name,
  }: let
    cfg = import ./${name}.nix;
  in {
    isNormalUser = true;
    createHome = true;
    description = "${cfg.fullName}";
    extraGroups = [
      "networkmanager"
      "wheel"
      "dialout"
      "plugdev"
      "wireshark"
      "tty"
      "audio"
      "video"
      "kvm"
      "docker"
      "libvirtd"
      "cdrom"
    ];
    openssh.authorizedKeys.keyFiles = [../../keys/${name}.keys];
    shell = pkgs.${cfg.shell};
    initialHashedPassword = cfg.initialHashedPassword;
  };

  mkHomeManager = {
    inputs,
    users,
  }: {
    extraSpecialArgs = {inherit inputs;};
    useUserPackages = true;
    useGlobalPkgs = true;
    users = lib.genAttrs users (name:
      import
      ../home-manager/profiles/${name}.nix);
  };
}
