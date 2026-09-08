{
  lib,
  buildNpmPackage,
  fetchurl,
  makeWrapper,
  playwright,
}:

# npm playwright is pinned to the nixpkgs playwright version in postPatch,
# and the wrapper points PLAYWRIGHT_BROWSERS_PATH at the nixpkgs browser
# build. The upstream postinstall (`playwright install --with-deps
# chromium`) downloads a browser and apt-installs system libraries as
# root, which cannot work on NixOS; scripts are skipped for that reason.

buildNpmPackage rec {
  pname = "mcp-mermaid";
  version = "0.4.1";

  src = fetchurl {
    url = "https://registry.npmjs.org/mcp-mermaid/-/mcp-mermaid-${version}.tgz";
    hash = "sha256-fBSMxpWWouWm5XmusCfMowzMv29CZGB/ad6qLXS3OLg=";
  };

  # The npm tarball ships the compiled JS, so only dependencies are needed.
  dontNpmBuild = true;

  postPatch = ''
    # Pin npm playwright to the nixpkgs version so the browser revision
    # expected at runtime matches ${playwright.version} from nixpkgs.
    substituteInPlace package.json \
      --replace-fail '"playwright": "^1.52.0"' '"playwright": "${playwright.version}"'
    # The npm tarball has no lock file; this one is generated from the
    # patched package.json (playwright pinned to the nixpkgs version).
    cp ${./package-lock.json} package-lock.json
  '';

  npmFlags = [ "--ignore-scripts" ];

  npmDepsHash = "sha256-soUsRarhkrVO2heXYfrGX0Oj3IA4S2Pb8Sh5WE+rd8Q=";

  postFixup = ''
    wrapProgram $out/bin/mcp-mermaid \
      --set PLAYWRIGHT_BROWSERS_PATH ${playwright.browsers}
  '';

  meta = {
    description = "MCP server that renders mermaid diagrams to SVG, PNG and other formats";
    homepage = "https://github.com/hustcc/mcp-mermaid";
    license = lib.licenses.mit;
    mainProgram = "mcp-mermaid";
    platforms = [ "x86_64-linux" ];
  };
}
