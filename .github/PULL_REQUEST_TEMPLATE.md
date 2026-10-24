## What

<!-- One or two sentences. Link the issue: Closes #123 -->

## Type

- [ ] New public workflow
- [ ] New action
- [ ] Change to an existing workflow or action
- [ ] Catalog CI, docs or tooling

## Checklist

- [ ] PR title follows Conventional Commits. Use `feat!:` or a `BREAKING CHANGE:` footer if an input, output, secret or file name changed or was removed.
- [ ] New or changed components have a `_test-*` workflow and are registered in `_ci.yml`.
- [ ] Third-party actions are pinned to a full commit SHA with a `# vX.Y.Z` comment.
- [ ] Jobs declare least-privilege `permissions:`.
- [ ] Component README and `examples/callers/` updated.
- [ ] `make lint` passes locally.
