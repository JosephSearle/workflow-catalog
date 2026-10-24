# Contributing

## Setup

Requires `docker`, `uv` and `pre-commit`.

```sh
pre-commit install
make lint
```

## Add a component

1. Open an issue with the matching form (new workflow or new action). Agree the name and contract first: names are public API.
2. Branch from `main`.
3. Scaffold:
   ```sh
   make new-action NAME=setup-node-cached   # actions/<name>/ + _test-action-<name>.yml
   make new-workflow NAME=node-ci           # workflow + _test-wf-<name>.yml + caller example
   ```
4. Implement it, following [docs/authoring-workflows.md](docs/authoring-workflows.md) or [docs/authoring-actions.md](docs/authoring-actions.md).
5. Write tests and register them in `_ci.yml`. See [docs/testing.md](docs/testing.md).
6. Add a row to the catalog table in `README.md`.
7. Run `make lint`, then open a PR.

## Commits and PR titles

Use [Conventional Commits](https://www.conventionalcommits.org/). PRs are squash-merged, so the PR title becomes the commit and drives the release.

| Prefix | Use for | Release |
| --- | --- | --- |
| `feat:` | New workflow, action, input or output | minor |
| `fix:` | Bug fix | patch |
| `deps:` | Dependency bumps | patch |
| `feat!:` or `BREAKING CHANGE:` footer | Removed or renamed input, output, secret or file; changed default behaviour | major |
| `docs:` `ci:` `chore:` `test:` `refactor:` | No change for consumers | none |

## Review

`ci-ok` must pass. `CODEOWNERS` routes every PR to @JosephSearle.
