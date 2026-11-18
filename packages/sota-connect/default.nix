{
  lib,
  stdenvNoCC,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  gtk3,
  glib,
  libsecret,
  libayatana-appindicator,
  curl,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "sota-connect";
  version = "1.8.11";

  src = fetchurl {
    url = "https://github.com/sotavpn/sotavpn-app/releases/download/v${finalAttrs.version}/sotaconnect_amd64.deb";
    hash = "sha256-ODuOXe4+/urWjGnhzCfZBgEplon3ZOc/2l6hSvufp2U=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
  ];

  buildInputs = [
    gtk3
    glib
    libsecret
    libayatana-appindicator
    curl
  ];

  # shortcut: the vendor package has an unused JNI plugin without a JVM, add a JVM if Sota makes it required.
  autoPatchelfIgnoreMissingDeps = [
    "libjawt.so"
    "libjvm.so"
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/lib/sota-connect" "$out/libexec/sota-connect"
    cp -r usr/lib/sota-connect/. "$out/lib/sota-connect/"
    cp usr/libexec/sota-connect/kittend "$out/libexec/sota-connect/"
    ln -s ../lib/sota-connect/sotavpn "$out/bin/sotavpn"

    install -Dm644 usr/share/applications/org.interhive.sota.connect.desktop \
      "$out/share/applications/org.interhive.sota.connect.desktop"
    substituteInPlace "$out/share/applications/org.interhive.sota.connect.desktop" \
      --replace-fail /usr/bin/sotavpn sotavpn
    cp -r usr/share/icons "$out/share/"

    install -Dm644 usr/lib/systemd/system/sota-connect.service \
      "$out/lib/systemd/system/sota-connect.service"
    substituteInPlace "$out/lib/systemd/system/sota-connect.service" \
      --replace-fail /usr/libexec/sota-connect/kittend "$out/libexec/sota-connect/kittend"

    runHook postInstall
  '';

  meta = {
    description = "Official Sota Connect VPN client";
    homepage = "https://sotavpn.ws/ru";
    license = lib.licenses.unfree;
    mainProgram = "sotavpn";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
