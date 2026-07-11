{
  pkgs,
  pkgs-unstable,
  ...
}: {
  home.packages = [
    pkgs.claude-code
    pkgs.codex
    pkgs-unstable.opencode
    pkgs-unstable.gemini-cli
    pkgs-unstable.grok-cli
    # pkgs.claude-code-router
  ];
}
