---
paths:
  - ".github/workflows/_test-*.yml"
  - ".github/workflows/_ci.yml"
  - "tests/fixtures/**"
---

# Tests

- `_test-action-<name>.yml` runs `./actions/<name>` with real inputs. `_test-wf-<name>.yml` calls `./.github/workflows/<name>.yml` with `working-directory: tests/fixtures/<name>`.
- Assert outputs and side effects in a separate step, and fail with `::error::` and a clear message.
- Test failure paths. For actions, run with `continue-on-error: true` and assert `steps.<id>.outcome == 'failure'`. For workflows, a calling job can't set `continue-on-error`, so the failing-fixture call goes in `_ci.yml` as `test-wf-<name>-failing` (kept out of `ci-ok.needs`), with a `test-wf-<name>-failing-assert` job in `ci-ok.needs` that checks its result is `failure`.
- Fixtures stay minimal and never need secrets, so tests run on every PR, including from forks.
- Use an OS matrix only for runners the component claims to support.
- A test only runs once it's registered in `_ci.yml`: a `changes` filter that covers the component, its test and its fixtures (plus any actions a workflow uses); an output; a `test-…` job; and an entry in `ci-ok.needs`.

Full guide: [docs/testing.md](../../docs/testing.md).
