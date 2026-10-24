# Authoring actions

Start with `make new-action NAME=<verb-noun>`. It creates `actions/<name>/` and `_test-action-<name>.yml` from [templates/](../templates/).

## When to write an action vs a workflow

| Need | Build |
| --- | --- |
| A full CI/CD process a repo calls (jobs, runners, permissions) | Reusable workflow |
| A self-contained unit of steps that a repo could use on its own | Action |
| Steps that only make sense inside one workflow | Inline steps in that workflow |

Actions are independent building blocks, and workflows compose them. An action doesn't need a second workflow before it exists, but it does need to stand on its own:

- It does one job with a clear result, e.g. "Node set up and dependencies installed", and a consumer repo could call it directly in its own workflow.
- It holds real logic: detection, validation, verified downloads. Don't wrap a single third-party action just to pass its inputs through. Use the third-party action directly.
- Its inputs and outputs are a contract you're willing to keep. They're public API under the catalog's version, so changing them later is a major release.

When a workflow's steps meet these rules, move them into an action and have the workflow use it through the `.catalog` checkout (see [authoring-workflows.md](authoring-workflows.md#use-catalog-actions)). Moving steps doesn't change the workflow's contract.

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
