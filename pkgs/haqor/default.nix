# SPDX-License-Identifier: MIT
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  copyDesktopItems,
  pkg-config,
  makeDesktopItem,
  wrapGAppsHook3,
  atk,
  cairo,
  fontconfig,
  gdk-pixbuf,
  glib,
  gtk3,
  harfbuzz,
  libGL,
  libepoxy,
  pango,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "haqor";
  version = "0.7.16";

  # The upstream release tarball is a Flutter Linux bundle built on Ubuntu, so
  # it needs autoPatchelf rather than a source build. Building from source
  # would mean running flutter + rustup + `rinf gen` codegen, which the
  # project's devshell does imperatively and Nix cannot reproduce offline.
  src = fetchurl {
    url = "https://github.com/machshev/haqor/releases/download/v${finalAttrs.version}/haqor-${finalAttrs.version}-linux-x64.tar.gz";
    hash = "sha256-F5jHFffUoD2XYrsYxeRD418dCg5f1EGfCKaeOdN8KVU=";
  };

  # The release bundle carries no icon; take it from the matching tag.
  icon = fetchurl {
    name = "haqor-icon.png";
    url = "https://raw.githubusercontent.com/machshev/haqor/v${finalAttrs.version}/assets/icon/icon.png";
    hash = "sha256-vTGQKomwbSXZKqds/FZpoE6ju62O7kZKBNsuPf9ZeCg=";
  };

  sourceRoot = ".";

  # Preloaded in front of GTK so the window comes up undecorated; see the
  # comment in no-titlebar.c.
  noTitlebar = ./no-titlebar.c;

  nativeBuildInputs = [
    autoPatchelfHook
    copyDesktopItems
    pkg-config
    wrapGAppsHook3
  ];

  buildInputs = [
    atk
    cairo
    fontconfig
    gdk-pixbuf
    glib
    gtk3
    harfbuzz
    libGL
    libepoxy
    pango
    stdenv.cc.cc.lib
  ];

  # libdartjni.so is the Android half of the `jni` plugin and is bundled on
  # every platform. Nothing on the desktop loads it, and there is no JVM to
  # link it against.
  autoPatchelfIgnoreMissingDeps = ["libjvm.so"];

  desktopItems = [
    (makeDesktopItem {
      name = "haqor";
      desktopName = "Haqor";
      comment = "Study the Hebrew and Greek scriptures";
      exec = "haqor";
      icon = "haqor";
      categories = ["Education"];
      keywords = ["Bible" "Hebrew" "Greek" "Scripture"];
    })
  ];

  buildPhase = ''
    runHook preBuild

    $CC -shared -fPIC -o libhaqor-no-titlebar.so "$noTitlebar" \
      $(pkg-config --cflags --libs gtk+-3.0)

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/haqor"
    cp -r haqor lib data "$out/share/haqor/"

    mkdir -p "$out/bin"
    # The runner finds its bundle through /proc/self/exe, which resolves the
    # symlink, so data/ and lib/ are located correctly.
    ln -s "$out/share/haqor/haqor" "$out/bin/haqor"

    install -Dm755 libhaqor-no-titlebar.so "$out/lib/libhaqor-no-titlebar.so"

    install -Dm644 "$icon" "$out/share/icons/hicolor/1024x1024/apps/haqor.png"

    runHook postInstall
  '';

  # wrapGAppsHook3 builds the bin/haqor wrapper; hang the preload off it so
  # the desktop entry and the WM keybinding both get an undecorated window.
  preFixup = ''
    gappsWrapperArgs+=(--prefix LD_PRELOAD " " "$out/lib/libhaqor-no-titlebar.so")
  '';

  meta = {
    description = "Haqor Bible study application";
    homepage = "https://github.com/machshev/haqor";
    license = lib.licenses.gpl3Only;
    platforms = ["x86_64-linux"];
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    mainProgram = "haqor";
  };
})
