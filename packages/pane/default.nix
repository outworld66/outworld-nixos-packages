{
  appimageTools,
  fetchurl,
  lib,
}:

let
  pname = "pane";
  version = "2.4.95";

  src = fetchurl {
    url = "https://github.com/dcouple/Pane/releases/download/v${version}/Pane-${version}-linux-x86_64.AppImage";
    hash = "sha256-fMp+C6owGusJe427GSO+NgBrCIZvO1GIjpHD6blWOf0=";
  };

  contents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm644 ${contents}/pane.desktop $out/share/applications/pane.desktop
    substituteInPlace $out/share/applications/pane.desktop \
      --replace-fail "Exec=AppRun" "Exec=pane"
    install -Dm644 ${contents}/usr/share/icons/hicolor/1024x1024/apps/pane.png \
      $out/share/icons/hicolor/1024x1024/apps/pane.png
  '';

  meta = {
    description = "Terminal-first AI code assistant manager";
    homepage = "https://github.com/dcouple/Pane";
    license = lib.licenses.agpl3Only;
    mainProgram = "pane";
    platforms = [ "x86_64-linux" ];
  };
}
