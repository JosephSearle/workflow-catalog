# Test fixtures

Small sample projects that public workflows run against in their `_test-wf-*` workflows. One directory per workflow or stack, e.g. `tests/fixtures/node-ci/`.

Rules:

- Keep fixtures minimal. They exist to exercise the workflow, not to be real projects.
- Add a failing fixture (e.g. `node-ci-failing/`) where the workflow should catch an error, and assert that it does. Workflow failure cases run from `_ci.yml`; see [docs/testing.md](../../docs/testing.md).
- Fixtures must not need secrets.
