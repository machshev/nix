{
  pkgs,
  pkgs-unstable,
  ...
}: {
  home.packages = [
    pkgs.claude-code
    pkgs.codex
    pkgs-unstable.opencode
    pkgs-unstable.grok-cli
  ];
}
