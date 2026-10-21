{
  buildNpmPackage,
  fetchurl,
  lib,
  nodejs_24,
}:

buildNpmPackage {
  pname = "openhands-agent-canvas";
  version = "1.27.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/@openhands/agent-canvas/-/agent-canvas-1.27.0.tgz";
    hash = "sha256-sPeb8GZ05geHH+oPNG4kwMUcMQYnz2/6SbYeh9+SvZs=";
  };

  nodejs = nodejs_24;
  npmDepsHash = "sha256-5wpg7IPzispZTZm1u7YksEZgRH3C1lyoFnCLufcJAkE=";
  npmFlags = [ "--ignore-scripts" ];
  dontNpmBuild = true;
  postPatch = ''
    cp ${./package-lock.json} package-lock.json
    patch -p1 < ${./oidc-env.patch}
  '';

  meta = {
    description = "OpenHands Agent Canvas web application";
    homepage = "https://github.com/OpenHands/OpenHands";
    license = lib.licenses.mit;
    mainProgram = "agent-canvas";
    platforms = [ "x86_64-linux" ];
  };
}
