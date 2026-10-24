# Authoring actions

Start with `make new-action NAME=<verb-noun>`. It creates `actions/<name>/` and `_test-action-<name>.yml` from [templates/](../templates/).

## When to write an action vs a workflow

| Need | Build |
| --- | --- |
| A full CI/CD process a repo calls (jobs, runners, permissions) | Reusable workflow |
| Steps shared by two or more workflows | Action |
| Steps used by one workflow only | Inline steps in that workflow |

Don't create an action until a second workflow needs the steps.

## Composite actions (default)

- `name`, `description` and `author` are set.
- Every input and output has a `description`. Inputs have a `default` unless they're required.
- Every `run` step sets `shell:`.
- Inputs reach scripts through `env:`, never `${{ }}` inside `run:`.
- Scripts longer than ~20 lines go in `actions/<name>/scripts/` and are called with `"$GITHUB_ACTION_PATH/scripts/<file>.sh"`.
- Don't call one catalog action from another. `uses: ./...` resolves against the workspace, not the action, and `uses:` can't contain expressions. Keep actions flat and compose them in workflows.
- Pin any third-party action used inside an action to a full commit SHA.

## TypeScript actions (when needed)

Add these when the first TypeScript action lands, not before:

- `actions/<name>/{src/,dist/,package.json,tsconfig.json}`, `runs.using: node24`, `main: dist/index.js`.
- Commit the bundled `dist/`. CI rebuilds it and fails if the result differs.
- Unit tests in the `_test-action-<name>` workflow, plus the usual integration test.
- Add `npm` with `directories: ["/actions/*"]` to `.github/dependabot.yml`.

## README

Each action's README covers usage, inputs, outputs and supported runners. List the action in [actions/README.md](../actions/README.md).
