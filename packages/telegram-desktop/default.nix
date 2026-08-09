{
  stdenvNoCC,
  lib,
  fetchurl,
  buildFHSEnv,
  makeDesktopItem,
  writeTextDir,
  glib,
  freetype,
  fontconfig,
  libpulseaudio,
  alsa-lib,
}:

let
  version = "7.0.5";

  desktopItem = makeDesktopItem {
    name = "org.telegram.desktop";
    desktopName = "Telegram";
    genericName = "Messenger";
    comment = "Official desktop version of Telegram messaging app";
    exec = "telegram-desktop -- %u";
    icon = "org.telegram.desktop";
    terminal = false;
    startupWMClass = "TelegramDesktop";
    categories = [
      "Chat"
      "Network"
      "InstantMessaging"
      "Qt"
    ];
    mimeTypes = [ "x-scheme-handler/tg" ];
  };

  telegramIcon = fetchurl {
    url = "https://raw.githubusercontent.com/telegramdesktop/tdesktop/v${version}/Telegram/Resources/art/icon256.png";
    hash = "sha256-P7FADH3Ju8O1yz/+3L9KmwnFPii1en/zOoprkEiGQJA=";
  };

  telegram = stdenvNoCC.mkDerivation {
    pname = "telegram-desktop-unwrapped";
    inherit version;

    src = fetchurl {
      url = "https://github.com/telegramdesktop/tdesktop/releases/download/v${version}/tsetup.${version}.tar.xz";
      hash = "sha256-N+I84IMzNAUEYjBCEguCb3oqVlDIMRhyGaucUgdA60I=";
    };

    sourceRoot = "Telegram";

    installPhase = ''
      runHook preInstall
      install -Dm755 Telegram "$out/bin/Telegram"
      runHook postInstall
    '';
  };

  # Telegram's supported integration point for distribution-managed updates.
  # Its presence disables the built-in updater for this executable.
  externalUpdaterMarker = writeTextDir "share/TelegramDesktop/externalupdater.d/telegram-desktop" ''
    ${telegram}/bin/Telegram
  '';
in
buildFHSEnv {
  name = "telegram-desktop";
  inherit version;

  targetPkgs =
    pkgs: with pkgs; [
      glib
      freetype
      fontconfig
      libpulseaudio
      alsa-lib
      wayland
      libxkbcommon
      xkeyboard_config
      libGL
      dbus
      gtk3
      libx11
      libxext
      libxrender
      libxcb
      xcb-util-cursor
      xcbutilimage
      xcbutilkeysyms
      xcbutilrenderutil
      xcbutilwm
      externalUpdaterMarker
    ];

  runScript = "${telegram}/bin/Telegram -noupdate";

  extraInstallCommands = ''
    install -Dm644 ${telegramIcon} "$out/share/icons/hicolor/256x256/apps/org.telegram.desktop.png"
    ln -s org.telegram.desktop.png "$out/share/icons/hicolor/256x256/apps/telegram.png"
    ln -s org.telegram.desktop.png "$out/share/icons/hicolor/256x256/apps/telegram-desktop.png"
    cp -r ${desktopItem}/share/. "$out/share/"
  '';

  meta = {
    description = "Official Telegram Desktop binary";
    homepage = "https://desktop.telegram.org/";
    license = lib.licenses.gpl3Only;
    mainProgram = "telegram-desktop";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
