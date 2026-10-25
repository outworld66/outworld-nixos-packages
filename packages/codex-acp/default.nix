{
  buildNpmPackage,
  fetchurl,
  lib,
  nodejs_24,
}:

buildNpmPackage {
  pname = "codex-acp";
  version = "0.16.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/@zed-industries/codex-acp/-/codex-acp-0.16.0.tgz";
    hash = "sha256-Ym+So8SFsrFEItvLgRghHlTf9h1BogUjSTKevRXrPSI=";
  };

  nodejs = nodejs_24;
  npmDepsHash = "sha256-Hj18Ws/lmVQU6FUdhhhMvqw18hrl9ziwClb2GoPV0CY=";
  npmFlags = [ "--ignore-scripts" ];
  dontNpmBuild = true;
  postPatch = "cp ${./package-lock.json} package-lock.json";

  meta = {
    description = "ACP-compatible coding agent powered by Codex";
    homepage = "https://github.com/zed-industries/codex-acp";
    license = lib.licenses.asl20;
    mainProgram = "codex-acp";
    platforms = [ "x86_64-linux" ];
  };
}
