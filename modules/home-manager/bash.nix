{...}: {
  # Manage ~/.bashrc declaratively so it can't drift into hand-edited cruft.
  #
  # Even though the login shell is fish, sshd sources ~/.bashrc when running a
  # remote command (e.g. `ssh host nix-store --serve` used by deploy-rs/nix).
  # Any stray output there corrupts the binary protocol stream and breaks
  # deploys with "'nix-store --serve' protocol mismatch". Home Manager's
  # generated .bashrc returns early for non-interactive shells, so it stays
  # quiet during those sessions.
  programs.bash.enable = true;

  # Reuse the same aliases defined for the interactive shell.
  # (home.shellAliases applies to bash too.)
}
