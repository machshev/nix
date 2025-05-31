{
  runCommand,
  lib,
}:
runCommand "dev-udev-rules" {
  meta.platforms = lib.platforms.linux;
} ''
  mkdir -p $out/etc/udev/rules.d
  cp ${./.}/*.rules $out/etc/udev/rules.d/
''
