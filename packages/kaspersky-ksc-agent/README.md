# Kaspersky Security Center Network Agent

This directory packages the upstream Kaspersky Network Agent Debian payload as
a Nix derivation. It intentionally contains no server address, registration
settings, certificates or NixOS enablement module; consumers provide those.

Build it from the package-library repository with:

```bash
NIXPKGS_ALLOW_UNFREE=1 nix build --impure \
  .#kaspersky-ksc-agent --no-link --print-build-logs
```
