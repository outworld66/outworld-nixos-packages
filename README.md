# outworld-nixos-packages

Reusable package derivations shared by `outworld-nixos-configs` and its
optional private library. This repository contains code for building packages,
not user identities, organization settings, host configuration or secrets.

Every `packages/*/default.nix` is exported automatically under
`packages.x86_64-linux`:

- `ferrite`
- `kaspersky-ksc-agent`
- `network-manager-amneziawg`
- `rlsp-yaml`
- `telegram-desktop`

The repository deliberately exports no NixOS modules, Home Manager modules,
git identities or organization configuration. Consumers own all enablement and
settings. As a library it does not commit `flake.lock`; the consuming flake
locks its inputs.

Package-local reusable integration may be exposed through package passthru.
For example, `kaspersky-ksc-agent.nixosModule` contains generic service logic
and safe protocol defaults, while consumers must provide the server address.

This repository must be publicly fetchable because the public system flake
uses it without SSH credentials.
