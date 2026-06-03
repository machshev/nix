{pkgs-unstable, ...}: {
  home.packages = [
    pkgs-unstable.claude-code
    pkgs-unstable.opencode
    pkgs-unstable.gemini-cli
    pkgs-unstable.grok-cli
    # pkgs.claude-code-router
  ];
}
