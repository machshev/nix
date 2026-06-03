{
  pkgs,
  pkgs-unstable,
  ...
}: {
  home.packages = [
    pkgs-unstable.claude-code
    pkgs.opencode
    # pkgs.claude-code-router
  ];
}
