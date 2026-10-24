# workflow-catalog

[![CI](https://github.com/JosephSearle/workflow-catalog/actions/workflows/_ci.yml/badge.svg?branch=main)](https://github.com/JosephSearle/workflow-catalog/actions/workflows/_ci.yml)
[![License: MIT](https://img.shields.io/github/license/JosephSearle/workflow-catalog)](LICENSE)

> Reusable GitHub Actions workflows and actions for all of JosephSearle's repos.

One place to change CI/CD, versioned so each repo upgrades when it chooses.

A reusable workflow is a workflow file that another repo runs as one of its jobs with `uses:`. An action is a smaller building block that runs as a single step. This repo holds both, tests them, and releases them under one version.

<details>
<summary>Table of Contents</summary>

- [Security](#security)
- [Install](#install)
  - [Dependencies](#dependencies)
- [Usage](#usage)
- [Catalog](#catalog)
- [Versioning](#versioning)
- [Repo layout](#repo-layout)
- [Maintainers](#maintainers)
- [Contributing](#contributing)
- [License](#license)

</details>

## Security

Report vulnerabilities privately as described in [SECURITY.md](SECURITY.md). Don't open a public issue.

Pin the catalog by full commit SHA, and grant each called workflow only the permissions its README lists. The rules catalog code follows, and the repo settings that enforce them, are in [docs/security.md](docs/security.md).

## Install

There's nothing to install. Your repo references the catalog by Git ref, and GitHub runs the workflows on its own runners.

To keep those refs current, add a Dependabot group to `.github/dependabot.yml` in your repo:

```yaml
version: 2
updates:
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
    groups:
      workflow-catalog:
        patterns: ["JosephSearle/workflow-catalog*"]
```

Dependabot then opens a weekly PR that bumps every catalog pin that has a version comment.

### Dependencies

- A GitHub repo with Actions enabled.
- Secrets passed one by one under `secrets:`. `secrets: inherit` only works within one organization or enterprise, and this catalog lives on a personal account.

## Usage

Call a workflow from a job in your repo's `.github/workflows/`:

```yaml
permissions: {}

jobs:
  ci:
    uses: JosephSearle/workflow-catalog/.github/workflows/<workflow>.yml@<sha> # v1.2.3
    permissions:
      contents: read
    with:
      working-directory: .
```

Replace `<workflow>` with a name from the [Catalog](#catalog), and `<sha>` with the commit of the release you want. On the next run, the called workflow's jobs show up in your checks as `ci / <job name>`.

Copy a ready-made caller from [examples/callers/](examples/callers/). For ref choices, secrets, permissions and limits, see [docs/consuming.md](docs/consuming.md).

## Catalog

### Workflows

| Workflow | Purpose | Example caller |
| --- | --- | --- |
| [node-ci](.github/workflows/node-ci.yml) | Node and TypeScript CI: detects pnpm (needs `packageManager` in package.json) or npm from the lockfile and Node from `.nvmrc` or `.node-version`, does a frozen install, then runs the `lint`, `typecheck`, `test` and `build` scripts that exist. Tested on `ubuntu-latest`. Callers grant `contents: read`. | [node-ci.yml](examples/callers/node-ci.yml) |

### Actions

| Action | Purpose |
| --- | --- |
| _none yet_ | |

Actions are building blocks for the workflows above. See [actions/README.md](actions/README.md).

## Versioning

The repo is released as a whole with semantic versioning.

- `vX.Y.Z` tags are immutable releases.
- `vX` tags move to the latest `vX.Y.Z`. They start at `v1`. There's no `v0`.
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
| `scripts/` | Helpers for `make` targets. |
| `docs/` | Authoring, testing, versioning and security guides, plus ADRs. |
| `.claude/` | Optional Claude Code skills, hooks, rules and a reviewer agent for authoring components. |

## Maintainers

[@JosephSearle](https://github.com/JosephSearle)

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a PR. Agree a new component's name in an issue first, because names are public API.

Local tooling needs `docker`, `uv` and `pre-commit`. Run the same checks as CI before you push:

```bash
pre-commit install
make lint
```

`make lint` runs actionlint, yamllint, schema validation and zizmor, and exits non-zero on any finding. Run `make help` to list every target.

PR titles must be [Conventional Commits](https://www.conventionalcommits.org/), e.g. `feat(node-ci): add coverage output`. The title becomes the squash commit and drives the release.

## License

[MIT](LICENSE) © 2026 Joseph William Searle
