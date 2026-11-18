{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  glibc,
  libgcc,
}:

# Binary repack of the official upstream tarball. MailCraft is an egui app
# statically linked against its GUI/TLS stack, so only glibc is needed.
# Rebuild from the nixpkgs Rust packaging when the project grows unpacked
# native dependencies.
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "mailcraft";
  version = "0.40.0";

  src = fetchurl {
    url = "https://github.com/ZIDAN44/mailcraft/releases/download/v${finalAttrs.version}/mailcraft-${finalAttrs.version}-linux-x86_64.tar.gz";
    hash = "sha256-K4oTI40amUF7OVSezSqGzYpQenusyarQVF5t/3pziow=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [
    glibc
    libgcc
  ];

  installPhase = ''
    runHook preInstall

    # The tarball root contains bin/ and share/ directly, the top-level
    # directory name is only in the archive path.
    mkdir -p "$out"
    cp -a bin share "$out/"

    runHook postInstall
  '';

  # autoPatchelf moves the embedded interpreter to the store; nothing else
  # to fix up - the tarball ships desktop files, icons and metainfo already.
  meta = {
    description = "Local-first, open-source email client (Outlook alternative) in Rust";
    homepage = "https://mailcraft.dev/";
    license = [
      lib.licenses.mit
      lib.licenses.asl20
    ];
    mainProgram = "mailcraft";
    platforms = [ "x86_64-linux" ];
  };
})
