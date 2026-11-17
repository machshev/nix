{
  writeShellApplication,
  coreutils,
  curl,
  jq,
  gitMinimal,
  opencode,
}:
writeShellApplication {
  name = "local-npu";
  # Use the host Podman, which carries the NixOS rootless storage/helper setup.
  runtimeInputs = [coreutils curl jq gitMinimal opencode];
  runtimeEnv.LOCAL_NPU_ASSETS = toString ./.;
  text = builtins.readFile ./local-npu.sh;
}
