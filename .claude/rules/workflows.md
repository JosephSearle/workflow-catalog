---
paths:
  - ".github/workflows/**"
---

# Workflows

- Unprefixed files in `.github/workflows/` are public reusable workflows, and their file names are public API. `_*.yml` files are internal (catalog CI, lint, release, tests) and are never called by consumers.
- `on.workflow_call` is the contract. Every input has `type` and `description`, and a `default` unless the caller must decide. Include a `working-directory` input so tests can point at fixtures. Declare each secret with a `description`, and add `required: true` only when the workflow can't run without it.
- Wire outputs step → job → `on.workflow_call.outputs`.
- Removing or renaming an input, output, secret or the file, changing a default's behaviour, or raising the permissions callers must grant is a **major** release. Prefer a new optional input with a default.
- Use catalog actions through a second checkout of `${{ job.workflow_repository }}` at `${{ job.workflow_sha }}` into `.catalog`, then `uses: ./.catalog/actions/<name>`. A bare `./actions/<name>` resolves against the caller's repo.
- Leave `concurrency` to the caller. Design for callers that set `cache-mode: read`.
- List the total permissions callers must grant in the README catalog row.

Full guide: [docs/authoring-workflows.md](../../docs/authoring-workflows.md). Semver rules: [docs/versioning.md](../../docs/versioning.md).
