{
  buildNpmPackage,
  fetchFromGitHub,
  lib,
  nodejs_24,
}:

buildNpmPackage {
  pname = "openhands-agent-canvas";
  version = "1.28.1-oidc-rbac";

  src = fetchFromGitHub {
    owner = "outworld66";
    repo = "OpenHands";
    rev = "c79ada52d";
    hash = "sha256-dP42uwq2EJbRw6Xl9eEFfLy9Q1HSg63u99hpcQNeOvI=";
  };

  nodejs = nodejs_24;
  npmDepsHash = "sha256-V3GG7zKW5xqCsdZ4/R9ZVp2LH9sHb2x7lGHvwQkQ9f8=";
  npmFlags = [ "--ignore-scripts" ];
  postPatch = ''
    patch -p1 < ${./oidc-env.patch}
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/node_modules/@openhands/agent-canvas $out/bin
    cp -r bin build config node_modules package.json scripts tools $out/lib/node_modules/@openhands/agent-canvas/
    ln -s ../lib/node_modules/@openhands/agent-canvas/bin/agent-canvas.mjs $out/bin/agent-canvas
    runHook postInstall
  '';

  meta = {
    description = "OpenHands Agent Canvas web application";
    homepage = "https://github.com/OpenHands/OpenHands";
    license = lib.licenses.mit;
    mainProgram = "agent-canvas";
    platforms = [ "x86_64-linux" ];
  };
}
