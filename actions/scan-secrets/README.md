# scan-secrets

Scans the full Git history for secrets with [gitleaks](https://github.com/gitleaks/gitleaks). gitleaks is a pinned release binary (currently 8.30.1), checked against a sha256 hash before use. It honours `.gitleaks.toml` and `.gitleaksignore` at the repo root, or a `config` path.

The action needs a full-history checkout (`fetch-depth: 0`). On a shallow checkout it fails with `result: error`, because otherwise it would only scan the fetched commits. Afterwards, `gitleaks` is on `PATH` for later steps, such as pre-commit hooks.

The [shell-lint](../../.github/workflows/shell-lint.yml) workflow is built on this action.

## Usage

Inside a catalog workflow, after checking out the catalog to `.catalog`:

```yaml
- uses: ./.catalog/actions/scan-secrets
  with:
    config: ${{ inputs.gitleaks-config }}
```

From any other repo:

```yaml
- uses: actions/checkout@<sha> # vX.Y.Z
  with:
    fetch-depth: 0
    persist-credentials: false
- uses: JosephSearle/workflow-catalog/actions/scan-secrets@<sha> # vX.Y.Z
```

To adopt it on a repo that still has old secrets in its history, set `fail-on-findings: "false"` and read the `result` output. Rotate each secret, then list its fingerprint in `.gitleaksignore`.

## Inputs

| Name | Required | Default | Description |
| --- | --- | --- | --- |
| `config` | no | `""` | Path to a gitleaks config, relative to the repo root. Empty uses `.gitleaks.toml` at the repo root, or gitleaks' default rules. |
| `fail-on-findings` | no | `"true"` | `"true"` fails the step when secrets are found. `"false"` reports them as a warning and in `result` without failing. A scan that can't run always fails. |

## Outputs

| Name | Description |
| --- | --- |
| `result` | `success` (no secrets), `failure` (secrets found) or `error` (shallow checkout, missing config, or gitleaks couldn't be installed or run). |

## Supported runners

Linux x64 and arm64 (tested on `ubuntu-latest` and `ubuntu-24.04-arm`).
