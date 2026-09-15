{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook4,
  glib,
  gtk4,
  libadwaita,
  libepoxy,
  pango,
  cairo,
  harfbuzz,
  gdk-pixbuf,
  graphene,
  vulkan-loader,
  ncurses,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "agterm";
  version = "0.26.1";

  # Upstream umputun/agterm is macOS-only; this is the maintained Linux port.
  # The release tarball bundles the Swift runtime, libghostty, Ghostty
  # resources and zmx, and expects only GTK4/libadwaita from the host.
  # Building from source needs a Swift 6.3 toolchain (nixpkgs has 5.10), so
  # package the official relocatable tarball instead.
  src = fetchurl {
    url = "https://github.com/melonamin/agterm-linux/releases/download/linux-v${finalAttrs.version}/agterm-linux-v${finalAttrs.version}-x86_64.tar.gz";
    hash = "sha256-KDOjkVj8INYcLgX8xYkxu5rDvTm3wgKdKIB3kq+5cGg=";

  };

  strictDeps = true;

  nativeBuildInputs = [
    autoPatchelfHook
    wrapGAppsHook4
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    glib
    gtk4
    libadwaita
    libepoxy
    pango
    cairo
    harfbuzz
    gdk-pixbuf
    graphene
    vulkan-loader
  ];

  # Payload lives under opt; upstream launcher scripts resolve lib/, bin/zmx
  # and share/ relative to their own location, so keep it intact.
  installPhase = ''
    runHook preInstall

    mkdir -p "$out/opt/agterm-linux" "$out/bin" "$out/share/applications"
    cp -a . "$out/opt/agterm-linux/"

    install -Dm644 "$out/opt/agterm-linux/share/applications/io.github.melonamin.agterm.desktop" \
      "$out/share/applications/io.github.melonamin.agterm.desktop"
    substituteInPlace "$out/share/applications/io.github.melonamin.agterm.desktop" \
      --replace-fail "Exec=agterm-linux" "Exec=$out/bin/agterm-linux"
    mkdir -p "$out/share/icons" "$out/share/pixmaps"
    cp -a "$out/opt/agterm-linux/share/icons/hicolor" "$out/share/icons/"
    cp -a "$out/opt/agterm-linux/share/pixmaps" "$out/share/"

    runHook postInstall
  '';

  # Bundled Swift runtime and libghostty.
  addAutoPatchelfSearchPath = [ "$out/opt/agterm-linux/lib" ];

  dontWrapGApps = true;

  postFixup = ''
    makeWrapper "$out/opt/agterm-linux/bin/agterm-linux" "$out/bin/agterm-linux" \
      "''${gappsWrapperArgs[@]}" \
      --suffix TERMINFO_DIRS : "$out/opt/agterm-linux/share/terminfo"
    makeWrapper "$out/opt/agterm-linux/bin/agtermctl" "$out/bin/agtermctl"
  '';

  meta = {
    description = "agterm terminal for AI coding agents (GTK4/libadwaita Linux port)";
    longDescription = ''
      Linux-maintained fork of umputun/agterm: a native GTK4/libadwaita
      terminal over the shared agtermCore controller, control API and
      agtermctl CLI, with the Ghostty (libghostty) terminal engine.
    '';
    homepage = "https://github.com/melonamin/agterm-linux";
    changelog = "https://github.com/melonamin/agterm-linux/releases/tag/linux-v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "agterm-linux";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
