# Security and repo settings

Consumer repos run catalog code with their own tokens and secrets. A compromise here spreads to every caller, so these settings are required, not optional.

## Code rules

Enforced by `_lint.yml` (zizmor, actionlint) and review:

- `permissions: {}` at the top of every workflow, with least privilege per job.
- Third-party actions pinned to a full commit SHA with a `# vX.Y.Z` comment. Dependabot keeps them current, with a 7-day cooldown before taking new releases.
- Binaries downloaded in a workflow (e.g. shellcheck in `lint-shell`, gitleaks in `scan-secrets`) pinned to an exact version and checked against a pinned sha256 before use. Dependabot can't bump these, so upgrade them by hand with the same 7-day cooldown. Python tools run with `uvx` (e.g. pre-commit) are pinned to an exact version with an `--exclude-newer` cutoff, but their packages aren't hash-checked.
- `persist-credentials: false` on checkouts.
- No `${{ }}` interpolation inside `run:`. Use `env:`.
- No `pull_request_target`.
- Explicit `secrets:` contracts, no `secrets: inherit`.

## Azure sandbox

The `deploy-container-app` live test deploys to a real Azure Container App, the only catalog test that reaches outside GitHub.

- `_ci.yml` grants `id-token: write` to `test-action-deploy-container-app`. Only its `live` job uses it, and that job runs on `main` only (push or manual run).
- The job runs in the `catalog-sandbox` environment. Its federated credential trusts `repo:JosephSearle/workflow-catalog:environment:catalog-sandbox`, and the environment's custom branch policy allows only `main`. PR runs can't get an Azure token.
- The service principal holds `Contributor` on the sandbox app and `AcrPush` on its registry, nothing wider. Setup is in [azure-container-apps.md](azure-container-apps.md).
- `azure/login` is from a Marketplace verified creator (Azure), so the allowlist below doesn't need it.

## Claude Code config

`.claude/settings.json` registers a hook that runs `.claude/hooks/lint-edited.sh` on contributors' machines whenever Claude Code edits a file, and it pre-approves some `make` and read-only `gh` commands. Review changes to `.claude/` as carefully as changes to workflows. Keep hooks local and read-only: no network calls beyond the pinned linters, and no writes outside the repo.

## Repository settings

Apply these once in **Settings**.

### General

- Pull requests: allow **squash merging only**. Default commit message: **Pull request title**.
- Automatically delete head branches.

### Rulesets

**`main` branch ruleset** (target: default branch)

- Restrict deletions. Block force pushes.
- Require linear history.
- Require a pull request before merging. Required approvals: 0 (solo maintainer). Dismiss stale approvals on push.
- Require status checks to pass: `ci-ok` and `PR title`. Require branches to be up to date.

**Release tag ruleset** (target: tags matching `v*`)

- Restrict creations, updates and deletions.
- Bypass list: the release GitHub App only.

The bypass lets `_release.yml` create `vX.Y.Z` and move `vX`. Nobody else can create or move a version tag.

### Releases

- Enable **immutable releases**. Published `vX.Y.Z` releases and their tags can't be changed.

### Actions → General

- Actions permissions: allow actions created by GitHub, plus actions by Marketplace verified creators, plus this allowlist:
  `dorny/paths-filter@*, googleapis/release-please-action@*, zizmorcore/zizmor-action@*, astral-sh/setup-uv@*, pnpm/action-setup@*`
- **Require actions to be pinned to a full-length commit SHA.**
- Workflow permissions: **Read repository contents**. Leave "Allow GitHub Actions to create and approve pull requests" **off**. The release app creates PRs instead.
- Fork PR workflows: require approval for all outside collaborators.

### Code security

- Dependabot alerts and security updates: on.
- Secret scanning and push protection: on.
- Private vulnerability reporting: on (used by [SECURITY.md](../SECURITY.md)).
- Code scanning: `_ci.yml`'s `zizmor-sarif` job uploads SARIF on pushes to `main`, and is the only job with `security-events: write`. On PRs and in the merge queue, `_lint.yml`'s zizmor job fails on findings instead. No default CodeQL setup needed for YAML-only content.

## Apply with `gh`

Rulesets and most toggles can be scripted. Check them in the UI after applying:

```sh
REPO=JosephSearle/workflow-catalog

# Squash-only merges, title as commit message, delete merged branches
gh api -X PATCH repos/$REPO \
  -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false \
  -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=PR_BODY \
  -F delete_branch_on_merge=true

# Read-only default token, no PR creation by GITHUB_TOKEN
gh api -X PUT repos/$REPO/actions/permissions/workflow \
  -f default_workflow_permissions=read -F can_approve_pull_request_reviews=false

# Private vulnerability reporting
gh api -X PUT repos/$REPO/private-vulnerability-reporting
```
