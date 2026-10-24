# Actions

Independent building blocks. Catalog workflows compose them, and other repos can use them directly. One directory per action, kebab-case verb-noun names.

Create one with `make new-action NAME=<name>`. See [docs/authoring-actions.md](../docs/authoring-actions.md).

| Action | Kind | Description |
| --- | --- | --- |
| [setup-node-deps](setup-node-deps/) | Composite | Detects pnpm or npm and the Node version, sets both up with caching, and does a frozen install, including in workspaces. |
| [scan-secrets](scan-secrets/) | Composite | Scans the full Git history for secrets with a pinned, hash-checked gitleaks, and reports findings and errors separately. |
| [setup-python-deps](setup-python-deps/) | Composite | Finds `uv.lock` (including in a uv workspace root), sets up uv with caching and Python, and runs `uv sync --locked`. |
