# workflow-catalog

Reusable GitHub Actions workflows and actions for all of JosephSearle's repos. One place to change CI/CD, versioned so each repo upgrades when it chooses.

## Usage

Call a workflow from a job in your repo's `.github/workflows/`:

```yaml
jobs:
  ci:
    uses: JosephSearle/workflow-catalog/.github/workflows/<workflow>.yml@<sha> # v1.2.3
    permissions:
      contents: read
    with:
      working-directory: .
```

Copy a ready-made caller from [examples/callers/](examples/callers/). For pinning, secrets and Dependabot setup, see [docs/consuming.md](docs/consuming.md).

## Catalog

### Workflows

| Workflow | Purpose | Example caller |
| --- | --- | --- |
| _none yet_ | | |

### Actions

| Action | Purpose |
| --- | --- |
| _none yet_ | |

Actions are building blocks for the workflows above. See [actions/README.md](actions/README.md).

## Versioning

The repo is released as a whole with semantic versioning.

- `vX.Y.Z` tags are immutable releases.
- `vX` tags move to the latest `vX.Y.Z`.
- Breaking changes to an input, output, secret or file name only ship in a new major version.

Details: [docs/versioning.md](docs/versioning.md). History: [CHANGELOG.md](CHANGELOG.md).

## Repo layout

| Path | Contents |
| --- | --- |
| `.github/workflows/<name>.yml` | Public reusable workflows. File names are public API. |
| `.github/workflows/_*.yml` | Internal: catalog CI, release and tests. Never call these. |
| `actions/<name>/` | Composite (and later TypeScript) actions. |
| `examples/callers/` | Copy-paste callers for consumer repos. |
| `templates/` | Skeletons used by `make new-action` and `make new-workflow`. |
| `tests/fixtures/` | Sample projects that workflow tests run against. |
| `docs/` | Authoring, testing, versioning and security guides, plus ADRs. |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Run `make help` for local tooling.

## License

[MIT](LICENSE)
