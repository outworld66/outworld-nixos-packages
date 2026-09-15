{
  stdenvNoCC,
  lib,
  fetchurl,
  dpkg,
  buildFHSEnv,
}:

let
  version = "0.10.63";

  src = fetchurl {
    url = "https://github.com/genspark-ai/genoffice/releases/download/v${version}/genoffice_${version}_amd64.deb";
    hash = "sha256-KQdKoZZ9eKZHWCuEyyZMEhLHXfqPWplBHEQE8Q/Th18=";
  };

  genoffice-unwrapped = stdenvNoCC.mkDerivation {
    pname = "genoffice-unwrapped";
    inherit version src;

    nativeBuildInputs = [ dpkg ];

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb --extract "$src" .
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/opt"
      cp -a opt/GenOffice "$out/opt/"

      # Icons, desktop entry and MIME types from the deb package
      mkdir -p "$out/share"
      cp -a usr/share/icons usr/share/applications usr/share/mime "$out/share/"

      # Point the desktop entry at the FHS wrapper
      substituteInPlace "$out/share/applications/genoffice.desktop" \
        --replace-fail "/opt/GenOffice/genoffice" "genoffice"
      runHook postInstall
    '';

    dontStrip = true;
  };
in
buildFHSEnv {
  name = "genoffice";
  inherit version;

  targetPkgs =
    pkgs: with pkgs; [
      # Chromium / Electron core
      nss
      nspr
      atk
      at-spi2-atk
      cups
      pango
      cairo
      expat
      fontconfig
      freetype
      gdk-pixbuf
      glib
      gtk3
      dbus
      udev

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
      libxscrnsaver
      xkeyboard_config

      # Audio
      alsa-lib

      # GPU / display
      mesa
      libgbm
      libdrm
      libGL
      libxkbcommon
      wayland

      # Electron extras (deb Depends)
      libnotify
      libsecret
    ];

  runScript = "${genoffice-unwrapped}/opt/GenOffice/genoffice";

  extraInstallCommands = ''
    cp -r ${genoffice-unwrapped}/share/. "$out/share/"
  '';

  meta = {
    description = "Open-source AI office suite with native docx, xlsx, pptx, pdf, html and markdown editors";
    homepage = "https://genoffice.ai/";
    license = lib.licenses.asl20;
    mainProgram = "genoffice";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
