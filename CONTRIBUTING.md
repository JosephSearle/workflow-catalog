# Contributing

Thanks for helping. This catalog runs CI/CD for every one of JosephSearle's repos, so a fix here fixes it everywhere. Code isn't the only way to help: bug reports with a failing run, docs fixes and comments on proposed components all count.

## Report a security issue

Don't open a public issue. Follow [SECURITY.md](SECURITY.md) and report privately through [GitHub private vulnerability reporting](https://github.com/JosephSearle/workflow-catalog/security/advisories/new).

## Report a bug

Open a [Bug](https://github.com/JosephSearle/workflow-catalog/issues/new?template=bug.yml) issue. Include:

- The component, e.g. `.github/workflows/node-ci.yml` or `actions/setup-node-cached`.
- The version or SHA your repo pins.
- A link to the failing run, if you have one.
- What happened and what you expected.

## Propose a component

New workflows and actions start with an issue: [New reusable workflow](https://github.com/JosephSearle/workflow-catalog/issues/new?template=new-workflow.yml) or [New action](https://github.com/JosephSearle/workflow-catalog/issues/new?template=new-action.yml). Agree the name and contract before you write code. Names, inputs, outputs and secrets are public API, and changing them later needs a major release.

Before proposing:

- A workflow needs a caller. Say which repos will use it.
- An action needs two workflows that share its steps. Steps used by one workflow stay inline. See [docs/authoring-actions.md](docs/authoring-actions.md).
- Prefer a new optional input with a default over changing an existing component's behaviour.

## Small changes vs. behaviour changes

- **Docs, typos, comments, catalog tooling:** open a PR directly.
- **Changes to how an existing workflow or action behaves:** open a PR and explain the problem in its description. If it removes or renames an input, output, secret or file, or changes a default, call it out. It ships as a major release.

## Set up

Requires `docker`, `uv` and `pre-commit`. Fork the repo if you don't have write access, then:

```sh
git clone https://github.com/<you>/workflow-catalog.git
cd workflow-catalog
pre-commit install
make lint
```

`make lint` runs the same checks as CI: actionlint, yamllint, schema validation and zizmor. zizmor runs its online audits too when `GH_TOKEN` is set or `gh` is logged in. Run `make help` to list every target.

Optional: if you use [Claude Code](https://claude.com/claude-code), the project config in `.claude/` adds `/new-workflow`, `/new-action` and `/pin-action` skills, a `catalog-reviewer` agent, and a hook that lints each workflow or action file after Claude edits it. See [CLAUDE.md](CLAUDE.md).

## Add a component

1. Get the issue agreed (see [Propose a component](#propose-a-component)).
2. Branch from `main`.
3. Scaffold:
   ```sh
   make new-action NAME=setup-node-cached   # actions/<name>/ + _test-action-<name>.yml
   make new-workflow NAME=node-ci           # workflow + _test-wf-<name>.yml + caller example
   ```
4. Implement it, following [docs/authoring-workflows.md](docs/authoring-workflows.md) or [docs/authoring-actions.md](docs/authoring-actions.md).
5. Write tests, add fixtures under `tests/fixtures/` for workflows, and register the test in `_ci.yml`. See [docs/testing.md](docs/testing.md).
6. Add a row to the catalog table in `README.md`.
7. Run `make lint`, then open a PR.

## Commits and PR titles

Use [Conventional Commits](https://www.conventionalcommits.org/): `<type>(<scope>)?: <description>`, e.g. `feat(node-ci): add coverage output`. The scope is optional and kebab-case. PRs are squash-merged, so the PR title becomes the commit and drives the release.

| Prefix | Use for | Release |
| --- | --- | --- |
| `feat:` | New workflow, action, input or output | minor |
| `fix:` | Bug fix | patch |
| `deps:` | Dependency bumps | patch |
| `perf:` `refactor:` | Internal change consumers might notice in run time or logs | patch |
| `revert:` | Reverting an earlier change | patch |
| `feat!:` or `BREAKING CHANGE:` footer | Removed or renamed input, output, secret or file; changed default behaviour | major |
| `docs:` `ci:` `chore:` `test:` | No change for consumers | none |

## Pull requests

Fill in the [PR template](.github/PULL_REQUEST_TEMPLATE.md). Its checklist covers pinning, permissions and tests.

- `ci-ok` and `PR title` must pass. Workflows on PRs from forks wait for approval before they run.
- `CODEOWNERS` routes every PR to @JosephSearle. Expect a first response within a week.
