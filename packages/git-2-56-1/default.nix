{
  stdenvNoCC,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  zstd,
  makeWrapper,
  curl,
  expat,
  glib,
  libsecret,
  zlib-ng,
}:

# git-2.56.1-1 links versioned symbols (PCRE2_10.47) that the unversioned
# nixpkgs pcre2 cannot satisfy (glibc warns on every git invocation), so ship
# the Arch core pcre2 10.49-1 it was built against.
let
  pcre2Arch = stdenvNoCC.mkDerivation {
    pname = "pcre2";
    version = "10.49";

    src = fetchurl {
      url = "https://geo.mirror.pkgbuild.com/core/os/x86_64/pcre2-10.49-1-x86_64.pkg.tar.zst";
      hash = "sha256-439BUv+GmmugUK0IMH17a0dPTUjL4MbMwBzpEYp3Tb8=";
    };

    nativeBuildInputs = [ zstd ];

    unpackPhase = ''
      runHook preUnpack
      tar --zstd -xf "$src"
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib"
      cp -a usr/lib/libpcre2-8.so.0* "$out/lib/"
      runHook postInstall
    '';
  };
in

# Temporary binary repack of Arch git 2.56.1-1 (security release fixing
# CVE-2026-114466/114467/114469 among others) until nixpkgs nixos-26.05
# ships 2.56.1 from source. Delete this package when nixpkgs catches up.
stdenv.mkDerivation (finalAttrs: {
  pname = "git";
  version = "2.56.1";

  src = fetchurl {
    url = "https://geo.mirror.pkgbuild.com/extra/os/x86_64/git-${finalAttrs.version}-1-x86_64.pkg.tar.zst";
    hash = "sha256-4DsX+lPsua9BoAtZn1ME+v2qBL02yf3QTrGK19f1N60=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    zstd
  ];

  buildInputs = [
    curl
    expat
    glib
    libsecret
    pcre2Arch
    zlib-ng # Arch builds git against libz-ng.so.2, not libz.so.1
  ];

  # Arch 2.56.1 links git-imap-send against OpenSSL 4 (libssl.so.4), which
  # nixpkgs-26.05 does not ship. git-imap-send stays broken; everything else
  # resolves against current nixpkgs libraries.
  autoPatchelfIgnoreMissingDeps = [
    "libssl.so.4"
    "libcrypto.so.4"
  ];

  unpackPhase = ''
    runHook preUnpack
    tar --zstd -xf "$src"
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out" "$out/libexec" "$out/share"
    cp -a usr/bin "$out/bin"
    cp -a usr/lib/git-core "$out/libexec/git-core"
    cp -a usr/share/git-core "$out/share/git-core"

    runHook postInstall
  '';

  # Arch builds with prefix /usr; git resolves subcommands and templates
  # from compiled-in paths that do not exist on NixOS, so point them at
  # the store locations.
  postFixup = ''
    wrapProgram "$out/bin/git" \
      --set GIT_EXEC_PATH "$out/libexec/git-core" \
      --set GIT_TEMPLATE_DIR "$out/share/git-core/templates"
  '';

  # git-imap-send and the perl subcommands (git-svn, git-send-email, git-p4)
  # stay broken: the former needs libssl.so.4 (OpenSSL 4, unavailable in
  # nixpkgs-26.05), the latter keep /usr/bin/perl shebangs. Add nix perl
  # wrappers with vendor paths if those are ever needed.
  meta = {
    description = "Distributed version control system, repacked from Arch extra 2.56.1-1";
    homepage = "https://git-scm.com/";
    mainProgram = "git";
    platforms = [ "x86_64-linux" ];
  };
})
