{
  installShellFiles,
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "d8";
  version = "0.34.9";

  src = fetchurl {
    url = "https://github.com/deckhouse/deckhouse-cli/releases/download/v${finalAttrs.version}/d8-v${finalAttrs.version}-linux-amd64.tar.gz";
    hash = "sha256-ZOMySh/MPgiPbdInVOBfZcd1O6xZuqsMC54oaHE1D5Q=";
  };

  nativeBuildInputs = [ installShellFiles ];

  installPhase = ''
    runHook preInstall
    install -Dm555 bin/d8 "$out/bin/d8"
    runHook postInstall
  '';

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd d8 \
      --bash <("$out/bin/d8" completion bash) \
      --fish <("$out/bin/d8" completion fish) \
      --zsh <("$out/bin/d8" completion zsh)
  '';

  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/d8" --help >/dev/null
    runHook postInstallCheck
  '';

  doInstallCheck = true;

  __structuredAttrs = true;

  meta = {
    description = "Deckhouse Kubernetes Platform CLI";
    homepage = "https://deckhouse.io/products/kubernetes-platform/documentation/v1/cli/d8/";
    changelog = "https://github.com/deckhouse/deckhouse-cli/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    mainProgram = "d8";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
