# Kaspersky Security Center Network Agent

This directory packages the upstream Kaspersky Network Agent Debian payload as
a Nix derivation. Its reusable NixOS module is attached as
`kaspersky-ksc-agent.nixosModule` through package passthru and provides safe
protocol defaults. It intentionally contains no server address, certificates
or consumer enablement; consumers provide those.

Build it from the package-library repository with:

```bash
NIXPKGS_ALLOW_UNFREE=1 nix build --impure \
  .#kaspersky-ksc-agent --no-link --print-build-logs
```
