# setup-node-deps

Detects pnpm or npm from the lockfile and Node from `.nvmrc` or `.node-version`, sets up both with dependency caching, then does a frozen install (`pnpm install --frozen-lockfile` or `npm ci`) where the lockfile is.

The lockfile can be in `working-directory` or in a parent workspace root: a directory with `pnpm-workspace.yaml` for pnpm, or a `package.json` with `"workspaces"` for npm. pnpm needs a `"packageManager": "pnpm@<version>"` field in that `package.json`. The action fails with an error if there's no usable lockfile.

Run it after checking out the repo. It doesn't run any `package.json` scripts. For the full CI job, use the [node-ci](../../.github/workflows/node-ci.yml) workflow, which is built on this action.

## Usage

Inside a catalog workflow, after checking out the catalog to `.catalog`:

```yaml
- uses: ./.catalog/actions/setup-node-deps
  with:
    working-directory: ${{ inputs.working-directory }}
```

From any other repo:

```yaml
- uses: actions/checkout@<sha> # vX.Y.Z
  with:
    persist-credentials: false
- id: node
  uses: JosephSearle/workflow-catalog/actions/setup-node-deps@<sha> # vX.Y.Z
  with:
    working-directory: packages/app
- run: pnpm run deploy
  working-directory: packages/app
```

## Inputs

| Name | Required | Default | Description |
| --- | --- | --- | --- |
| `working-directory` | no | `.` | Directory containing `package.json`, relative to the repo root. The lockfile may be here or in a parent workspace root. |
| `node-version` | no | `""` | Node version spec, e.g. `22` or `lts/*`. Empty reads `.nvmrc` or `.node-version` from `working-directory`, then the workspace root, then the repo root, then falls back to `lts/*`. |

## Outputs

| Name | Description |
| --- | --- |
| `node-version` | Node version that was set up, e.g. `v22.11.0`. |
| `package-manager` | `pnpm` or `npm`, detected from the lockfile. |
| `lock-dir` | Directory holding the lockfile, relative to the repo root (`.` at the root). Install ran here. |

## Supported runners

ubuntu
