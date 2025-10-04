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
  }: let
    system = "x86_64-linux";
    pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
  in {
    extraSpecialArgs = {inherit inputs pkgs-unstable;};
    useUserPackages = true;
    useGlobalPkgs = true;
    users = lib.genAttrs users (name:
      import
      ../home-manager/profiles/${name}.nix);
  };
}
