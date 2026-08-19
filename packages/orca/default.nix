{
  stdenvNoCC,
  lib,
  fetchurl,
  dpkg,
  buildFHSEnv,
  makeDesktopItem,
}:

let
  version = "1.4.185";

  src = fetchurl {
    url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-ide_${version}_amd64.deb";
    hash = "sha256-UBNZIbFNdurrZswi8zhK36XLXu3JMEjcuFXgyChzHuI=";
  };

  desktopItem = makeDesktopItem {
    name = "orca-ide";
    desktopName = "Orca";
    genericName = "Agent Development Environment";
    comment = "ADE for working with a fleet of parallel AI agents";
    exec = "orca %U";
    icon = "orca-ide";
    terminal = false;
    categories = [
      "Development"
      "IDE"
    ];
    startupWMClass = "Orca";
  };

  orca-unwrapped = stdenvNoCC.mkDerivation {
    pname = "orca-unwrapped";
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
      cp -a opt/Orca "$out/opt/"

      # Icons from the deb package
      if [ -d usr/share/icons ]; then
        mkdir -p "$out/share/icons"
        cp -a usr/share/icons/. "$out/share/icons/"
      fi

      runHook postInstall
    '';

    dontStrip = true;
  };
in
buildFHSEnv {
  name = "orca";
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
      libdrm
      libGL
      libxkbcommon
      wayland

      # Electron extras
      libnotify
      libsecret
    ];

  runScript = "${orca-unwrapped}/opt/Orca/orca-ide";

  extraInstallCommands = ''
    mkdir -p "$out/share/icons" "$out/share/applications"
    cp -r ${orca-unwrapped}/share/icons/. "$out/share/icons/" 2>/dev/null || true
    cp -r ${desktopItem}/share/. "$out/share/"
  '';

  meta = {
    description = "Agent Development Environment for parallel AI agents";
    homepage = "https://onorca.dev/";
    license = lib.licenses.mit;
    mainProgram = "orca";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
