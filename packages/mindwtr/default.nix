{
  stdenvNoCC,
  lib,
  fetchurl,
  dpkg,
  buildFHSEnv,
}:

let
  version = "1.3.0";

  src = fetchurl {
    url = "https://github.com/dongdongbh/Mindwtr/releases/download/v${version}/mindwtr_${version}_amd64.deb";
    hash = "sha256-2B8doYrjkKbmR3dte2zS6v57+EWvzJwQZrDTIowkew8=";
  };

  mindwtr-unwrapped = stdenvNoCC.mkDerivation {
    pname = "mindwtr-unwrapped";
    inherit version src;

    nativeBuildInputs = [ dpkg ];

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb --extract "$src" .
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      install -Dm555 usr/bin/mindwtr "$out/bin/mindwtr"

      # Icons and desktop entries from the deb package. The hidden
      # mindwtr.desktop is intentional: Wayland compositors match the app id
      # (mindwtr) against it case-sensitively; Mindwtr.desktop stays visible.
      mkdir -p "$out/share"
      cp -a usr/share/icons usr/share/applications "$out/share/"
      runHook postInstall
    '';

    dontStrip = true;
  };
in
buildFHSEnv {
  name = "mindwtr";
  inherit version;

  targetPkgs =
    pkgs: with pkgs; [
      # Tauri core (deb Depends: libwebkit2gtk-4.1, libgtk-3, libappindicator3)
      webkitgtk_4_1
      gtk3
      libayatana-appindicator
      glib-networking
      shared-mime-info
      gdk-pixbuf
      pango
      cairo
      fontconfig
      freetype
      dbus

      # X11
      libx11
      libxcb
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      libxrender
      libxtst

      # GPU / display
      mesa
      libgbm
      libdrm
      libGL
      libxkbcommon
      wayland
    ];

  runScript = "${mindwtr-unwrapped}/bin/mindwtr";

  extraInstallCommands = ''
    cp -r ${mindwtr-unwrapped}/share/. "$out/share/"
  '';

  meta = {
    description = "Free, open-source Getting Things Done (GTD) and to-do app";
    homepage = "https://mindwtr.app/";
    license = lib.licenses.agpl3Only;
    mainProgram = "mindwtr";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
