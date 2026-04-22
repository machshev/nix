{pkgs, ...}: {
  home.packages = with pkgs; [
    claude-code
    opencode
    # claude-code-router
  ];
}
