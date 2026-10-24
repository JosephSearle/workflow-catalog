# Consuming the catalog

## Call a workflow

Reusable workflows are called at the **job** level, not as a step:

```yaml
permissions: {}

jobs:
  ci:
    uses: JosephSearle/workflow-catalog/.github/workflows/node-ci.yml@<sha> # v1.2.3
    permissions:
      contents: read        # grant what the workflow's README lists, nothing more
    with:
      working-directory: .
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

Start from the matching file in [examples/callers/](../examples/callers/).

## Pick a ref

| Ref | Example | When |
| --- | --- | --- |
| Full SHA + version comment | `@3f1c…a9 # v1.2.3` | Default. Immutable, and Dependabot bumps it with a PR. |
| Major tag | `@v1` | From 1.0.0 only, for low-risk repos that should get fixes automatically. There's no `v0`, because before 1.0.0 breaking changes ship as minor releases. |
| Branch | `@main` | Never. Unreleased and can break at any time. |

`uses:` can't contain expressions, so the ref has to be literal.

## Keep it current with Dependabot

Add to `.github/dependabot.yml` in the consumer repo:

```yaml
version: 2
updates:
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
    groups:
      workflow-catalog:
        patterns: ["JosephSearle/workflow-catalog*"]
```

Dependabot updates SHA pins that have a version comment, and opens a PR you can review against [CHANGELOG.md](../CHANGELOG.md).

## Secrets

Pass each secret the workflow declares explicitly under `secrets:`. `secrets: inherit` only works for callers in the same organization or enterprise, so it doesn't work here. A secret that isn't passed resolves to an empty string unless the workflow marks it `required: true`.

## Permissions

The caller's `GITHUB_TOKEN` permissions are a ceiling. A called workflow can keep or reduce them, never raise them. Each workflow's README lists what its jobs need. Set `permissions: {}` at the top of the caller and grant per job.

## Use an action directly

Actions are mainly for catalog workflows, but any repo can use one:

```yaml
- uses: JosephSearle/workflow-catalog/actions/<name>@<sha> # v1.2.3
```

## Limits

- Calls nest at most 10 levels deep, counting your caller.
- One workflow file can call at most 50 unique reusable workflows, including nested calls.
- Renamed workflows and actions are not redirected. A rename is a breaking change and ships only in a major release.
