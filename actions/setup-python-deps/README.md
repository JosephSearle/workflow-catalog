# setup-python-deps

Finds `uv.lock`, sets up uv with dependency caching and the requested Python, then runs `uv sync --locked`.

`uv.lock` can be in `working-directory` or in a parent directory (uv workspaces). In a workspace member, only that member's dependency groups are installed. The action fails with an error if there's no `pyproject.toml` in `working-directory` or no `uv.lock` up to the repo root.

Run it after checking out the repo. Afterwards, `uv run --no-sync <command>` in `working-directory` uses the installed environment. For the full CI job, use the [python-ci](../../.github/workflows/python-ci.yml) workflow, which is built on this action.

## Usage

Inside a catalog workflow, after checking out the catalog to `.catalog`:

```yaml
- uses: ./.catalog/actions/setup-python-deps
  with:
    working-directory: ${{ inputs.working-directory }}
```

From any other repo:

```yaml
- uses: actions/checkout@<sha> # vX.Y.Z
  with:
    persist-credentials: false
- id: python
  uses: JosephSearle/workflow-catalog/actions/setup-python-deps@<sha> # vX.Y.Z
  with:
    working-directory: services/api
- run: uv run --no-sync python -m api.migrate
  working-directory: services/api
```

## Inputs

| Name | Required | Default | Description |
| --- | --- | --- | --- |
| `working-directory` | no | `.` | Directory containing `pyproject.toml`, relative to the repo root. `uv.lock` may be here or in a parent directory. |
| `python-version` | no | `""` | Python version request, e.g. `3.12`. Empty lets uv resolve it: `.python-version`, then `requires-python` in `pyproject.toml`. |

## Outputs

| Name | Description |
| --- | --- |
| `python-version` | Python version in the project environment, e.g. `3.12.7`. |
| `lock-dir` | Directory holding `uv.lock`, relative to the repo root (`.` at the root). |

## Supported runners

ubuntu
