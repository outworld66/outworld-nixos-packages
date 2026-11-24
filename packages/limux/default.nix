{
  lib,
  stdenvNoCC,
  fetchurl,
  dpkg,
  patchelf,
  buildFHSEnv,
  glibc,
  librsvg,
}:

let
  version = "0.1.27";

  src = fetchurl {
    url = "https://github.com/am-will/limux/releases/download/v${version}/limux_${version}_amd64.deb";
    hash = "sha256-z63sKt60rUXQdwzRMGQK82W5sD9jNRzcaIha4UYjRTo=";
  };

  limux-unwrapped = stdenvNoCC.mkDerivation {
    pname = "limux-unwrapped";
    inherit version src;

    nativeBuildInputs = [
      dpkg
      patchelf
    ];

    unpackPhase = ''
      dpkg-deb --extract "$src" .
    '';

    installPhase = ''
      mkdir -p "$out"
      cp -a usr "$out/"
      # The upstream .deb ships ELFs without a runpath, so they normally rely
      # on the ld cache that buildFHSEnv fakes at runtime. extraBwrapArgs below
      # binds the real glibc /etc back over that fake cache, which breaks ELF
      # loading for the shipped binaries. Give them an explicit /usr/lib64
      # runpath instead: it resolves inside the FHS sandbox and stays out of
      # the ld cache, so the glibc store path keeps its original content.
      for elf in $out/usr/bin/limux \
        $out/usr/libexec/limux/limux-host \
        $out/usr/lib/limux/libghostty-internal.so; do
        patchelf --set-rpath /usr/lib64 "$elf"
      done
    '';

    dontStrip = true;
    # fixupPhase shrinks RUNPATH entries that do not exist at build time, which
    # would drop the /usr/lib64 runpath set above; it only resolves inside the
    # FHS sandbox at runtime.
    dontPatchELF = true;
  };
in
buildFHSEnv {
  name = "limux";
  inherit version;

  targetPkgs =
    pkgs: with pkgs; [
      limux-unwrapped
      gtk4
      libadwaita
      webkitgtk_6_0
      glib
      pango
      cairo
      gdk-pixbuf
      librsvg
      libepoxy
      libxkbcommon
      wayland
      gsettings-desktop-schemas
      mesa
      libdrm
      alsa-lib
      dbus
    ];

  runScript = "${limux-unwrapped}/usr/bin/limux";
  # buildFHSEnv mounts a tmpfs over ${glibc}/etc so a fake ld cache exists at
  # the store path (Steam pressure-vessel). That changes glibc's nar hash as
  # seen from inside the sandbox, so every nix build, copy or verify touching
  # glibc fails with a hash mismatch — deploys run from limux terminals kept
  # dying on `nix-copy-closure`. Limux is not a game env; nothing here reads the
  # fake cache. Bind the real directory back over the mask: extraBwrapArgs go
  # last, and bwrap resolves bind sources against the host namespace.
  extraBwrapArgs = [ "--ro-bind ${glibc}/etc ${glibc}/etc" ];

  profile = ''
    export GDK_PIXBUF_MODULE_FILE="${librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"
  '';

  extraBuildCommands = ''
    ln -s ${limux-unwrapped}/usr/lib/limux/libghostty-internal.so \
      $out/usr/lib64/libghostty-internal.so
  '';

  extraInstallCommands = ''
    mkdir -p "$out/usr/local/lib"
    ln -s "${limux-unwrapped}/usr/lib/limux" "$out/usr/local/lib/limux"
    cp -r ${limux-unwrapped}/usr/share/. "$out/share/"
    substituteInPlace "$out/share/applications/dev.limux.linux.desktop" \
      --replace-fail "/usr/bin/limux" "limux"
  '';

  meta = {
    description = "GPU-accelerated terminal workspace manager";
    homepage = "https://github.com/am-will/limux";
    license = lib.licenses.mit;
    mainProgram = "limux";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
