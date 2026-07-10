{
  pkgs,
  pkgs-unstable,
  ...
}: {
  home.packages = [
    # From the claude-code-nix overlay (github:sadjow/claude-code-nix) for up-to-date releases.
    pkgs.claude-code
    pkgs-unstable.opencode
    pkgs-unstable.gemini-cli
    pkgs-unstable.grok-cli
    pkgs-unstable.codex
    # pkgs.claude-code-router
  ];
}
