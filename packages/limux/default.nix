{
  lib,
  stdenvNoCC,
  fetchurl,
  dpkg,
  buildFHSEnv,
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

    nativeBuildInputs = [ dpkg ];

    unpackPhase = ''
      dpkg-deb --extract "$src" .
    '';

    installPhase = ''
      mkdir -p "$out"
      cp -a usr "$out/"
    '';

    dontStrip = true;
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
      libepoxy
      libxkbcommon
      wayland
      mesa
      libdrm
      alsa-lib
      dbus
    ];

  runScript = "${limux-unwrapped}/usr/bin/limux";

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
