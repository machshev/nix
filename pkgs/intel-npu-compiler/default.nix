# SPDX-License-Identifier: MIT
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  onetbb,
  zlib,
  zstd,
}:
# The NPU driver compiler that nixpkgs' intel-npu-driver leaves out. The
# Level Zero NPU driver dlopens libnpu_driver_compiler.so by bare name to turn
# OpenVINO IR into NPU code; without it every NPU compile fails.
#
# Keep the version in step with the intel-npu-driver the host runs.
stdenv.mkDerivation (finalAttrs: {
  pname = "intel-npu-compiler";
  version = "1.28.0";
  build = "20251218-20347000698";

  src = fetchurl {
    url = "https://github.com/intel/linux-npu-driver/releases/download/v${finalAttrs.version}/linux-npu-driver-v${finalAttrs.version}.${finalAttrs.build}-ubuntu2404.tar.gz";
    sha256 = "1hh3ip03fqkjpqgn6gck0sigwf66yqikkml56w59r1ziswks5k09";
  };

  nativeBuildInputs = [autoPatchelfHook dpkg];
  buildInputs = [onetbb zlib zstd stdenv.cc.cc.lib];

  sourceRoot = ".";
  unpackPhase = ''
    runHook preUnpack
    tar xzf $src ./intel-driver-compiler-npu_${finalAttrs.version}.${finalAttrs.build}_ubuntu24.04_amd64.deb
    dpkg-deb -x intel-driver-compiler-npu_*.deb .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 usr/lib/x86_64-linux-gnu/libnpu_driver_compiler.so -t $out/lib
    runHook postInstall
  '';

  meta = {
    description = "Intel NPU driver compiler (prebuilt), for the Level Zero NPU driver";
    homepage = "https://github.com/intel/linux-npu-driver";
    license = lib.licenses.asl20;
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    platforms = ["x86_64-linux"];
  };
})
