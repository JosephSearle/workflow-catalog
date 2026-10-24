# Authoring reusable workflows

Start with `make new-workflow NAME=<domain>-<purpose>`. It creates the workflow, its test and a caller example from [templates/](../templates/).

## Naming

- File: `.github/workflows/<domain>-<purpose>.yml`, kebab-case, e.g. `node-ci.yml`, `docker-publish.yml`.
- GitHub only finds reusable workflows directly in `.github/workflows/`, so file names have to separate public workflows from internal ones. Unprefixed files are public. Files starting with `_` are internal.
- The file name is public API. Renaming one is a breaking change.

## Contract

Each workflow's `on.workflow_call` block is its contract.

- **Inputs:** set `type` and `description` on every one. Give a `default` unless the caller must decide. Include `working-directory` so tests can run against fixtures.
- **Secrets:** declare each one with a `description`. Use `required: true` when the workflow can't run without it. Callers pass secrets explicitly.
- **Outputs:** map step output → job output → `on.workflow_call.outputs`.
- Prefer adding an optional input with a default over changing existing behaviour. That keeps the change non-breaking.

## Permissions

- Top level: `permissions: {}`.
- Each job declares only what it needs. Document the total in the workflow's README entry, because callers must grant at least that.

## Use catalog actions

`uses: ./actions/x` inside a reusable workflow resolves against the **caller's** checkout, not the catalog. Check out the catalog at the exact commit of the running workflow, then use the local path:

```yaml
- uses: actions/checkout@<sha> # vX.Y.Z
  with:
    repository: ${{ job.workflow_repository }}
    ref: ${{ job.workflow_sha }}
    path: .catalog
    persist-credentials: false
- uses: ./.catalog/actions/<name>
```

This keeps the workflow and its actions at the same version, including in PR tests. The `job.workflow_*` contexts arrived in September 2026 and aren't available on GitHub Enterprise Server.

Fallback if the `job.workflow_*` contexts stop working: reference `JosephSearle/workflow-catalog/actions/<name>@vX.Y.Z`, then add the file to `extra-files` in `release-please-config.json` so each release rewrites the ref.

## Security rules

- Pin third-party actions to a full commit SHA with a `# vX.Y.Z` comment.
- Use `persist-credentials: false` on every checkout unless a later step pushes.
- Never interpolate `${{ }}` directly into `run:`. Pass values through `env:` and reference `"$VAR"`.
- Don't use `pull_request_target` or `workflow_run` triggers in callers or examples without a written threat review.
- Set `timeout-minutes` on every job.

## Concurrency

Leave `concurrency` to the caller. The workflow can't know the caller's branching model.

## Caching

Callers can limit cache access for a called workflow with `cache-mode` (`read`, `write`, `write-only`, `none`) on the calling job. The limit only narrows access. Design workflows to work with `cache-mode: read`, e.g. for untrusted PRs.

## Docs

Add a row to the catalog table in [README.md](../README.md), listing the purpose, required permissions and caller example.
