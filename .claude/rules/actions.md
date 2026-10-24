---
paths:
  - "actions/**"
---

# Actions

- Actions are independent building blocks that workflows compose. Create one for a self-contained unit with real logic that a consumer repo could use on its own. Don't wrap a single third-party action, and keep steps that only make sense inside one workflow inline.
- Composite actions set `name`, `description` and `author: JosephSearle`. Every input and output has a `description`, and inputs have a `default` unless they're required.
- Every `run` step sets `shell:`. Inputs reach scripts through `env:`.
- Scripts longer than ~20 lines go in `actions/<name>/scripts/` and are called with `"$GITHUB_ACTION_PATH/scripts/<file>.sh"`.
- Don't call one catalog action from another. `uses: ./...` resolves against the workspace, and `uses:` can't contain expressions. Compose actions in workflows instead.
- Each action's README covers usage, inputs, outputs and supported runners. List the action in `actions/README.md` and the README catalog table.
- Input and output names are public API. Renaming or removing one is a major release.

Full guide: [docs/authoring-actions.md](../../docs/authoring-actions.md).
