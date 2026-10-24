# AGENTS.md

Guidance for AI coding agents working in this repository.

## What this repo is

A catalog of reusable GitHub Actions workflows and composite actions that JosephSearle's other repos call by Git ref. It's YAML and shell only: there's no build step. The whole repo is released under a single semver version. The public workflows are `node-ci` and `python-ci` (released in `v1.0.0`) and `shell-lint`. The one action is `setup-node-deps`, which `node-ci` uses.

## Commands

Local tooling needs `docker`, `uv` and `pre-commit`.

```sh
make lint                 # Everything CI checks: actionlint, yamllint, schema, zizmor
make actionlint           # Run one linter on its own (also: yamllint, schema, zizmor)
make lint-files FILES=.github/workflows/node-ci.yml   # Lint only the given workflow/action/template files
make template-pins        # Check that templates/ pins match the live pins
make sync-template-pins   # Rewrite templates/ pins to the live pins
make new-workflow NAME=node-ci            # Workflow + _test-wf-<name>.yml + examples/callers/<name>.yml
make new-action NAME=setup-node-cached    # actions/<name>/ + _test-action-<name>.yml
pre-commit run --all-files                # or: pre-commit run <hook-id> --files <path>
```

`make zizmor` runs online audits when `GH_TOKEN`, `GITHUB_TOKEN` or a `gh` login is available, and falls back to `--offline` otherwise. Behaviour tests (`_test-*.yml`) only run on GitHub in CI. `act` works on a best-effort basis, and CI is the source of truth.

Tool versions are pinned in four places that must stay in sync: the `Makefile` variables, `.pre-commit-config.yaml`, `_lint.yml` and `_ci.yml` (where the zizmor `version:` is set).

## Architecture

**Public vs internal workflows.** GitHub only finds reusable workflows directly in `.github/workflows/`, so the file name prefix separates them. Unprefixed files are public API: renaming one, or changing its inputs, outputs, secrets or defaults, is a major release. `_*.yml` files are internal: catalog CI, lint, release and tests.

**CI gate.** `_ci.yml` always runs, and its final `ci-ok` job is the required status check. It passes when every job in `needs` succeeded or was skipped, which avoids path-filtered required checks staying pending forever. The `PR title` check lives in `_pr-title.yml` so that editing a PR doesn't rerun the whole graph. On push to main, `zizmor-sarif` uploads findings to code scanning and is the only job with `security-events: write`. On PRs, `_lint.yml`'s zizmor job fails on findings instead.

**Registering a component** (not done automatically by `make new-*`). You edit `_ci.yml` by hand:
1. Add a filter covering the component, its `_test-*.yml` and its fixtures (`tests/fixtures/<name>/` and `<name>-failing/`). When a workflow uses an action, add the action's path to the workflow's filter too.
2. Expose the filter under `changes.outputs`.
3. Add a `test-…` job that calls the test workflow when the filter matched.
4. Add that job to `ci-ok.needs`.
5. A workflow's failing fixture runs from `_ci.yml` as `test-wf-<name>-failing` (not in `ci-ok.needs`) plus `test-wf-<name>-failing-assert` (in `ci-ok.needs`), because a job calling a reusable workflow can't set `continue-on-error`.
Then add a row to the Catalog table in `README.md`. List actions in `actions/README.md` as well.

**Workflows using catalog actions.** `uses: ./actions/x` inside a reusable workflow resolves against the *caller's* checkout. To use a catalog action, check out `${{ job.workflow_repository }}` at `${{ job.workflow_sha }}` into `.catalog` and then use `./.catalog/actions/<name>`. Don't delete `.catalog` during the job, because post steps of the actions it holds reload it at job end. Exclude it from git instead (see `docs/authoring-workflows.md`). Actions must not call other catalog actions; compose them in workflows instead. Actions are independent building blocks: create one for a self-contained unit with real logic that a consumer repo could use on its own, not a wrapper around a single third-party action.

**Template pins.** Dependabot doesn't scan `templates/`, so `scripts/template-pins.sh` copies the SHA pins from live files in `.github/workflows/` and `actions/` into the templates. `make new-*` runs the sync on each file it generates. Templates use `__NAME__` placeholders, which `sed` replaces.

**Releases.** release-please (`_release.yml`) runs on each push to main and needs a GitHub App token (`vars.RELEASE_APP_CLIENT_ID`, `secrets.RELEASE_APP_PRIVATE_KEY`), because PRs created with `GITHUB_TOKEN` don't trigger CI. The app is the only bypass actor on the `v*` tag ruleset. Merging the release PR tags an immutable `vX.Y.Z` and moves the floating `vX` tag. Breaking changes now need a new major version.

## Security rules for every workflow and action

These are enforced by zizmor, actionlint and review (see `docs/security.md`):

- Put `permissions: {}` at the top level and give each job least privilege. Set `timeout-minutes` on every job.
- Pin third-party actions to a full 40-char commit SHA with a `# vX.Y.Z` comment.
- Use `persist-credentials: false` on every checkout unless a later step pushes.
- Never interpolate `${{ }}` inside `run:`. Pass values through `env:` and use `"$VAR"`.
- Don't use `pull_request_target`, and don't use `secrets: inherit`, which doesn't work on a personal account anyway. Declare secrets explicitly with descriptions.

## Where the detailed rules live

Before editing a component, read the guide for that area: `docs/authoring-workflows.md` for public workflows, `docs/authoring-actions.md` for actions and `docs/testing.md` for `_test-*.yml`, fixtures and `_ci.yml`. Claude Code also loads short versions of these guides from `.claude/rules/` when it touches matching paths.

## Commits and PRs

PRs are squash-merged, and the PR title becomes the commit, which drives release-please. Titles must match `^(feat|fix|deps|perf|refactor|revert|docs|ci|chore|test)(\([a-z0-9-]+\))?!?: .+`. `feat` → minor; `fix`, `deps`, `perf`, `refactor` and `revert` → patch; `!` or a `BREAKING CHANGE:` footer → major; `docs`, `ci`, `chore` and `test` → no release.
