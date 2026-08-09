{
  lib,
  rustPlatform,
  fetchCrate,
}:

rustPlatform.buildRustPackage rec {
  pname = "rlsp-yaml";
  version = "0.9.0";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-T/FJ0RhjJNcadhz0vPMzzD3FKsANz5QcBIm5iGwvwIU=";
  };

  cargoHash = "sha256-3R2H7bnN3eKnZq1/ALrns1nhJw/4I3tgRViI+P01t/8=";

  # The crate archive excludes git-only conformance fixtures; its test targets
  # consequently trip the upstream `-D warnings` policy during a crates.io build.
  doCheck = false;

  meta = {
    description = "Fast, schema-aware YAML language server";
    homepage = "https://github.com/chdalski/rlsp";
    license = lib.licenses.mit;
    mainProgram = "rlsp-yaml";
  };
}
