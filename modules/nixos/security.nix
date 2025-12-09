{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
with lib; {
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  options = {};

  config = mkMerge [
    (mkIf (!config.machshev.server) {
      services.gnome.gnome-keyring.enable = true;
      security.pam.services.gdm.enableGnomeKeyring = true;
      security.pam.services.gdm-password.enableGnomeKeyring = true;
      programs.seahorse.enable = true;

      security.polkit.enable = true;

      services.fprintd.enable = true;

      security.pam.services.swaylock = {
        text = ''
          auth include login
        '';
        fprintAuth = true;
      };

      environment.systemPackages = with pkgs; [
        polkit
        polkit_gnome
      ];

      environment.pathsToLink = [
        "/libexec"
      ];

      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };

      services.pcscd.enable = true;
    })
    {
      sops = {
        # Use age (ED25519) instead of gpg (RSA)
        gnupg.sshKeyPaths = [];
      };
    }
  ];
}
