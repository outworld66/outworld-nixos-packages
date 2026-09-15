# Repository guide

This repository is a reusable Nix package library. Its flake exports package
derivations only. Keep it independent of organizations, users, hosts and the
public/private configuration repositories that consume it.

## Repository map

- `flake.nix`: automatic package discovery and package exports.
- `packages/<name>/default.nix`: one package derivation per directory.
- `packages/<name>/`: package-local patches, reusable package integration and
  build documentation.

## Validation

After Nix changes, run `nixfmt`, then
`nix flake check --no-build --no-write-lock-file --print-build-logs` and
`git diff --check`. Build a changed package explicitly when practical.

## Safety boundaries

- Top-level flake outputs must remain package derivations only. Generic
  package-local integration may be attached through passthru; identities,
  certificates, endpoints and consumer enablement belong in a consumer.
- Do not add credentials, tokens, private keys, personal identity or
  workstation-specific hardware data.
- Preserve exported package names unless all known consumers are updated in the
  same task.
- Keep credentials out of the repository regardless of the automated checks;
  the check is a heuristic gate, not permission to store credentials.

## Automated commit and push

When the requested changes are complete and the Validation requirements have
passed, commit and push to `origin/main` without asking for confirmation.
This permission is scoped to the current task only: stage the files this task
touched (explicit `git add <paths>`; `git add .` only when every change in
the worktree belongs to the task), and never commit in a sibling repository
as part of the same task.

Sequence:

1. Stage the task's files.
2. Run the secret check below; any match or suspicion aborts the automation.
3. Commit with a concise message describing the change.
4. Push the current branch to its existing upstream only. If the branch has
   no upstream, stop and ask. Never force-push.

### Mandatory secret check (after staging, before committing)

```bash
# suspicious file names in the staged change set
git diff --cached --name-only | grep -Ei \
  '(^|/)(\.env($|\.)|id_(rsa|ed25519|ecdsa)[^/]*|[^/]+\.(pem|key|p12|pfx)|secrets?)$'

# suspicious content in the staged diff
git diff --cached | grep -Ein \
  -e 'BEGIN [A-Z ]*PRIVATE KEY' \
  -e '(api[_-]?key|secret|token|pass(word|phrase)?|credential)[^a-zA-Z0-9_-]*[=:][[:space:]]*"[^"$]{8,}"' \
  -e '(AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{20}|github_pat_[A-Za-z0-9_]+|sk-[A-Za-z0-9]{20}|xox[abpr]-|glpat-[A-Za-z0-9_-]{20}|sk_live_[A-Za-z0-9]+|AIza[0-9A-Za-z_-]{20})'
```

Exit status 1 from both greps means clean. On any match, or on any other
suspicion of credential material in the diff (high-entropy literals,
credentials embedded in URLs, pasted agent output), do nothing further: do
not commit, do not push, and report the matching lines to the user. A
confirmed false positive may be committed after the user clears it.

Known non-secrets that do not block automation: `hash = "sha256-..."` values
in derivations and public test fixtures bundled by upstream.
- Do not activate systems. Committing and pushing follows the automated
  policy below and requires its mandatory secret check.
