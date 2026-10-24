# Test fixtures

Small sample projects that public workflows and actions run against in their `_test-wf-*` and `_test-action-*` workflows. One directory per workflow or stack, e.g. `tests/fixtures/node-ci/`. Actions reuse the fixtures of the workflow they came from and add their own only for cases it doesn't cover, e.g. `setup-node-deps-failing/`.

Rules:

- Keep fixtures minimal. They exist to exercise the workflow, not to be real projects.
- Add a failing fixture (e.g. `node-ci-failing/`) where the workflow should catch an error, and assert that it does. Workflow failure cases run from `_ci.yml`; see [docs/testing.md](../../docs/testing.md).
- Fixtures must not need secrets.
