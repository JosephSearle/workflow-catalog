# 1. Catalog structure, testing and versioning

- Status: Accepted
- Date: 2026-10-24

## Context

All of JosephSearle's repos need consistent CI/CD. Copying workflow YAML between repos drifts. GitHub Actions supports reusable workflows (`workflow_call`) and actions that other repos can reference by `owner/repo/path@ref`.

Constraints:

- Reusable workflows must sit directly in `.github/workflows/`, with no subdirectories.
- The repo is owned by a personal account. Organization workflow templates aren't available, and `secrets: inherit` doesn't work across repos.
- Inside a reusable workflow, `uses: ./actions/x` resolves against the caller's checkout.
- Renamed workflows and actions aren't redirected.

## Decision

1. **One public repo** holds reusable workflows (the product) and actions (shared building blocks). Public visibility lets public and private repos call it.
2. **Naming separates public from internal.** Unprefixed `.github/workflows/*.yml` files are public API. `_`-prefixed files are catalog-internal.
3. **Workflows check out the catalog at `job.workflow_sha`** to use catalog actions, so workflows and actions are always the same version.
4. **Composite actions by default.** TypeScript tooling is added when the first TS action needs it.
5. **Testing:** static checks on every PR, plus one test workflow per component, run only when that component changed. A single `ci-ok` gate job covers them, and a separate `PR title` check is the only other required check.
6. **Versioning:** the whole repo has one semver version, released by release-please from Conventional Commits. `vX.Y.Z` releases are immutable, and from 1.0.0 a floating `vX` tag is moved by the release app. Consumers pin by SHA (recommended) or, from 1.0.0, `vX`.
7. **Callers are distributed as copy-paste examples** in `examples/callers/` instead of workflow templates.

## Consequences

- Any release bumps the version of every component, even unchanged ones. Accepted for simplicity. Revisit per-component tags if the catalog grows large.
- `job.workflow_*` is a new context. If it regresses, the fallback is pinning actions by tag and having release-please rewrite those refs.
- actionlint 1.7.12 doesn't know `job.workflow_*` or the `$/` self-repository syntax. `.github/actionlint.yaml` and `.github/zizmor.yml` hold narrow suppressions to remove when actionlint catches up.
- Releases need a GitHub App (see `docs/versioning.md`).
- Moving to a GitHub organization later would enable workflow templates and `secrets: inherit`. That move is a breaking change, because every caller's `uses:` owner changes.
