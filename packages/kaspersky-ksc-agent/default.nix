{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  glibc,
  libxcrypt-legacy,
  perl,
}:

stdenv.mkDerivation {
  pname = "kaspersky-ksc-agent";
  version = "16.3.0-1207";

  src = fetchurl {
    url = "https://products.s.kaspersky-labs.com/administrationkit/ksc10/16.3.0.1207/russian-INT-31399824-ru/6f4294e2b3a64aa9aeec337f6a6699f5/klnagent64_16.3.0-1207_amd64.deb";
    hash = "sha256-wtn8nm0A7l63FkC8RqWLUpDDWSb48Y1mjgkdn3QYaL4=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
  ];

  buildInputs = [
    glibc
    libxcrypt-legacy
    perl
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb --extract "$src" .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/opt/kaspersky" "$out/bin" "$out/share/man/man1"
    cp -a opt/kaspersky/klnagent64 "$out/opt/kaspersky/"

    # The Debian package uses absolute links because it is normally installed
    # directly below /. Keep them valid after relocating the payload.
    ln -sfn ../lib/libcrypto_ssl_1_1.so \
      "$out/opt/kaspersky/klnagent64/bin/libcrypto_ssl_1_1.so"
    ln -sfn ../lib/libcrypto_ssl_1_1.so \
      "$out/opt/kaspersky/klnagent64/sbin/libcrypto_ssl_1_1.so"
    ln -sfn ../../lib/libcrypto_ssl_1_1.so \
      "$out/opt/kaspersky/klnagent64/sbin/protcomp/libcrypto_ssl_1_1.so"

    for program in klcsexec klmover klnagchk klscmodchk nagregister patchunix; do
      ln -s "$out/opt/kaspersky/klnagent64/bin/$program" "$out/bin/$program"
    done

    for page in "$out"/opt/kaspersky/klnagent64/share/man/man1/*; do
      cp -a "$page" "$out/share/man/man1/"
    done

    runHook postInstall
  '';

  dontStrip = true;

  preFixup = ''
    patchelf --remove-rpath \
      "$out/opt/kaspersky/klnagent64/sbin/protcomp/libftbridge.so"
  '';

  meta = {
    description = "Kaspersky Security Center Network Agent";
    homepage = "https://support.kaspersky.com/ksc/16.1/en-US/5022.htm";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "klmover";
    platforms = [ "x86_64-linux" ];
  };
}
