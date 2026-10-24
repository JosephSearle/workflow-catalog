---
paths:
  - ".github/workflows/_test-*.yml"
  - ".github/workflows/_ci.yml"
  - "tests/fixtures/**"
---

# Tests

- `_test-action-<name>.yml` runs `./actions/<name>` with real inputs. `_test-wf-<name>.yml` calls `./.github/workflows/<name>.yml` with `working-directory: tests/fixtures/<name>`.
- Assert outputs and side effects in a separate step, and fail with `::error::` and a clear message.
- Test failure paths: run the subject with `continue-on-error: true` (or against `tests/fixtures/<name>-failing/`), then assert `steps.<id>.outcome == 'failure'`.
- Fixtures stay minimal and never need secrets, so tests run on every PR, including from forks.
- Use an OS matrix only for runners the component claims to support.
- A test only runs once it's registered in `_ci.yml`: a `changes` filter that covers the component, its test and its fixtures (plus any actions a workflow uses); an output; a `test-…` job; and an entry in `ci-ok.needs`. The first component also uncomments `changes`.

Full guide: [docs/testing.md](../../docs/testing.md).
