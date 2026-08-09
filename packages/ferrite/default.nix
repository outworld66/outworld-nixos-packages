{
  inputs,
  lib,
  stdenv,
  symlinkJoin,
  makeWrapper,
  wayland,
  libxkbcommon,
  vulkan-loader,
  libGL,
  libx11,
  libxcursor,
  libxi,
  libxrandr,
  libxcb,
}:

let
  upstreamFerrite = inputs.ferrite.packages.${stdenv.hostPlatform.system}.default;
  upstreamSrc = inputs.ferrite;
in
symlinkJoin {
  name = "ferrite-${upstreamFerrite.version}";
  paths = [ upstreamFerrite ];
  nativeBuildInputs = [ makeWrapper ];

  postBuild = ''
    rm $out/bin/ferrite
    makeWrapper ${upstreamFerrite}/bin/ferrite $out/bin/ferrite \
      --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath [
          wayland
          libxkbcommon
          vulkan-loader
          libGL
          libx11
          libxcursor
          libxi
          libxrandr
          libxcb
        ]
      }

    install -Dm644 \
      ${upstreamSrc}/assets/linux/io.github.olaproeis.Ferrite.desktop \
      $out/share/applications/io.github.olaproeis.Ferrite.desktop
    install -Dm644 \
      ${upstreamSrc}/assets/linux/io.github.olaproeis.Ferrite.metainfo.xml \
      $out/share/metainfo/io.github.olaproeis.Ferrite.metainfo.xml

    for size in 16 32 48 64 128 256 512; do
      install -Dm644 \
        ${upstreamSrc}/assets/icons/icon_''${size}.png \
        $out/share/icons/hicolor/''${size}x''${size}/apps/io.github.olaproeis.Ferrite.png
    done
  '';

  inherit (upstreamFerrite) meta;
}
