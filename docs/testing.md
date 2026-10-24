# Testing

Every PR runs `_ci.yml`. Its final job, `ci-ok`, is the required status check for everything except the PR title, which `_pr-title.yml` checks as `PR title`.

## Layers

| Layer | Where | What |
| --- | --- | --- |
| Static | `_lint.yml` / `make lint` | actionlint (with shellcheck), yamllint, schema checks for `action.yml`/workflows/Dependabot, zizmor security audit |
| Action | `_test-action-<name>.yml` | Runs `./actions/<name>` with real inputs and asserts outputs and side effects |
| Workflow | `_test-wf-<name>.yml` | Calls `./.github/workflows/<name>.yml` against `tests/fixtures/<name>/` and asserts outputs. The `<name>-failing/` case runs from `_ci.yml` (see below) |

## Why one gate job

A required check that path filters skip stays "pending" forever and blocks the merge. `_ci.yml` always runs, and `ci-ok` passes when every job succeeded or was skipped. Its `changes` job works out which components changed (`dorny/paths-filter`) so only their test workflows run.

`PR title` lives in its own workflow because it has to rerun when the PR is edited. In `_ci.yml`, every description edit would rerun the whole graph.

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
5. For a workflow with a failing fixture, also add `test-wf-<name>-failing` and `test-wf-<name>-failing-assert`. Only the assert job goes in `ci-ok.needs` (see "Writing good tests").

When a workflow uses an action, add the action's path to the workflow's filter so action changes retest the workflow.

## Writing good tests

- Assert outputs and side effects in a separate step, and fail with `::error::` and a clear message.
- Test failure paths. For an action, run it with `continue-on-error: true`, then assert `steps.<id>.outcome == 'failure'`.
- For a workflow, the job that calls it can't set `continue-on-error`, and a failed call inside `_test-wf-<name>.yml` would fail the whole test. Put the failing case in `_ci.yml` instead: a `test-wf-<name>-failing` job calls the workflow with `tests/fixtures/<name>-failing`, and a `test-wf-<name>-failing-assert` job (`if: always()` plus the filter) fails unless `needs.test-wf-<name>-failing.result == 'failure'`. Only the assert job goes in `ci-ok.needs`. The expected-failure job shows as a red, non-required check on the PR. See `test-wf-node-ci-failing` for an example.
- Use a matrix across `ubuntu-latest`, `macos-latest` and `windows-latest` only for runners the component claims to support.
- Fixtures must not need secrets, so tests run on every PR.

## Local runs

- `make lint` runs the same static checks as CI.
- [`act`](https://github.com/nektos/act) can run test workflows locally on a best-effort basis. Reusable workflows and the newer contexts may not behave the same as on GitHub, so CI is the source of truth.

## Later: canary

Once there are several public workflows, add a scheduled `_canary.yml` that runs every `_test-*` workflow weekly on `main`. This catches drift in runner images and third-party actions between PRs.
