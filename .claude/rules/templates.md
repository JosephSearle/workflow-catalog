---
paths:
  - "templates/**"
  - "scripts/**"
  - "Makefile"
---

# Templates and scaffolding

- `make new-workflow` and `make new-action` copy `templates/` with `sed`, replacing `__NAME__` with the component name. Keep every per-component value as `__NAME__`.
- Templates must pass `make lint` as they are. Expected noise about `__NAME__` files that don't exist yet belongs in `.github/actionlint.yaml`, not in inline disables.
- Dependabot doesn't scan `templates/`. After changing a pin in `.github/workflows/` or `actions/`, run `make template-pins`, then `make sync-template-pins` if it reports drift. `scripts/template-pins.sh` treats live files as the source of truth.
- Makefile variables that reach a shell (`NAME`, `FILES`) are taken from the command line only, read literally with `$(value ...)` and validated before use. Keep that pattern for any new variable of this kind.
- Tool versions live in the Makefile variables and must match `.pre-commit-config.yaml`, `_lint.yml` and `_ci.yml`.
