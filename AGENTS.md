# Repository guide

This repository is a reusable Nix package library. Its flake exports package
derivations only. Keep it independent of organizations, users, hosts and the
public/private configuration repositories that consume it.

## Repository map

- `flake.nix`: automatic package discovery and package exports.
- `packages/<name>/default.nix`: one package derivation per directory.
- `packages/<name>/`: package-local patches and build documentation.

## Validation

After Nix changes, run `nixfmt`, then
`nix flake check --no-build --no-write-lock-file --print-build-logs` and
`git diff --check`. Build a changed package explicitly when practical.

## Safety boundaries

- Export only package derivations. NixOS modules, Home Manager modules,
  identities, certificates, endpoints and consumer enablement belong in the
  consuming configuration repository.
- Do not add credentials, tokens, private keys, personal identity or
  workstation-specific hardware data.
- Preserve exported package names unless all known consumers are updated in the
  same task.
- Do not activate systems, stage, commit or push unless explicitly requested.
