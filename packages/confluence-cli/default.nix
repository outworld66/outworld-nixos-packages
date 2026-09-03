{
  buildNpmPackage,
  fetchFromGitHub,
  lib,
}:

let
  version = "2.22.0";
in
buildNpmPackage {
  pname = "confluence-cli";
  inherit version;

  src = fetchFromGitHub {
    owner = "pchuri";
    repo = "confluence-cli";
    tag = "v${version}";
    hash = "sha256-UFaAOdjWl1n26acrFTXbYPBZTm9pZPOVFsl67bMphpg=";
  };

  npmDepsHash = "sha256-hpa7jSXZkIMS0k3z1BZQrkIC/PjQeqnWZb3RDbdnSAA=";

  dontNpmBuild = true;

  meta = {
    description = "Command-line interface for Atlassian Confluence";
    homepage = "https://github.com/pchuri/confluence-cli";
    license = lib.licenses.mit;
    mainProgram = "confluence";
    platforms = lib.platforms.unix;
  };
}
