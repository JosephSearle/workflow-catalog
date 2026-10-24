# lint-shell

Runs [shellcheck](https://github.com/koalaman/shellcheck) on the shell scripts in a directory. shellcheck is a pinned release binary (currently v0.11.0), checked against a sha256 hash before use.

It checks `*.sh` and `*.bash` files, plus any other file whose first line is a `sh`, `bash`, `dash` or `ksh` shebang. It skips `.git`, `node_modules`, `.venv` and a top-level `.catalog`. shellcheck honours the caller's `.shellcheckrc` and follows `source` to files next to each script.

Afterwards, `shellcheck` is on `PATH` for later steps, such as pre-commit hooks, even when the lint itself couldn't run (e.g. a missing directory).

The [shell-lint](../../.github/workflows/shell-lint.yml) workflow is built on this action, together with [scan-secrets](../scan-secrets/).

## Usage

Inside a catalog workflow, after checking out the catalog to `.catalog`:

```yaml
- uses: ./.catalog/actions/lint-shell
  with:
    working-directory: ${{ inputs.working-directory }}
```

From any other repo:

```yaml
- uses: actions/checkout@<sha> # vX.Y.Z
  with:
    persist-credentials: false
- uses: JosephSearle/workflow-catalog/actions/lint-shell@<sha> # vX.Y.Z
  with:
    working-directory: scripts
```

## Inputs

| Name | Required | Default | Description |
| --- | --- | --- | --- |
| `working-directory` | no | `.` | Directory to lint, relative to the repo root. |
| `fail-on-findings` | no | `"true"` | `"true"` fails the step when shellcheck finds problems. `"false"` reports them as a warning and in `result` without failing. A lint that can't run always fails. |

## Outputs

| Name | Description |
| --- | --- |
| `result` | `success`, `failure` (findings), `error` (missing `working-directory`, or shellcheck couldn't be installed or run) or `skipped` (no scripts found). |
| `files` | Space-separated scripts shellcheck checked, relative to `working-directory`. |
| `shellcheck-version` | shellcheck version that was installed, e.g. `v0.11.0`. Empty if it couldn't be installed. |

## Supported runners

Linux x64 and arm64 (tested on `ubuntu-latest` and `ubuntu-24.04-arm`).
