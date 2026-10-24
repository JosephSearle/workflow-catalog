# Testing

Every PR runs `_ci.yml`. Its final job, `ci-ok`, is the only required status check.

## Layers

| Layer | Where | What |
| --- | --- | --- |
| Static | `_lint.yml` / `make lint` | actionlint (with shellcheck), yamllint, schema checks for `action.yml`/workflows/Dependabot, zizmor security audit |
| Action | `_test-action-<name>.yml` | Runs `./actions/<name>` with real inputs and asserts outputs and side effects |
| Workflow | `_test-wf-<name>.yml` | Calls `./.github/workflows/<name>.yml` against `tests/fixtures/` and asserts outputs |

## Why one required check

A required check that path filters skip stays "pending" forever and blocks the merge. `_ci.yml` always runs. It works out which components changed (`dorny/paths-filter`), calls only their test workflows, and `ci-ok` passes when every job succeeded or was skipped.

## Register a component in `_ci.yml`

1. Add a filter covering the component, its test workflow and its fixtures:
   ```yaml
   action-setup-node-cached:
     - 'actions/setup-node-cached/**'
     - '.github/workflows/_test-action-setup-node-cached.yml'
   ```
2. Expose it under `changes.outputs`.
3. Add a job:
   ```yaml
   test-action-setup-node-cached:
     needs: changes
     if: needs.changes.outputs.action-setup-node-cached == 'true'
     uses: ./.github/workflows/_test-action-setup-node-cached.yml
     permissions:
       contents: read
   ```
4. Add the job to `ci-ok.needs`.

When a workflow uses an action, add the action's path to the workflow's filter so action changes retest the workflow.

## Writing good tests

- Assert outputs and side effects in a separate step, and fail with `::error::` and a clear message.
- Test failure paths: run the subject with `continue-on-error: true`, then assert `steps.<id>.outcome == 'failure'`.
- Use a matrix across `ubuntu-latest`, `macos-latest` and `windows-latest` only for runners the component claims to support.
- Fixtures must not need secrets, so tests run on every PR.

## Local runs

- `make lint` runs the same static checks as CI.
- [`act`](https://github.com/nektos/act) can run test workflows locally on a best-effort basis. Reusable workflows and the newer contexts may not behave the same as on GitHub, so CI is the source of truth.

## Later: canary

Once there are several public workflows, add a scheduled `_canary.yml` that runs every `_test-*` workflow weekly on `main`. This catches drift in runner images and third-party actions between PRs.
