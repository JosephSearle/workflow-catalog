---
name: new-workflow
description: Scaffold, implement, test and register a new public reusable workflow in this catalog, following docs/authoring-workflows.md and docs/testing.md. Use when someone wants to add a reusable workflow, e.g. "add a node-ci workflow".
argument-hint: <domain>-<purpose>
allowed-tools: Read, Grep, Glob, Edit, Write, Bash(make new-workflow *), Bash(make lint), Bash(make lint-files *), Bash(gh issue list *), Bash(gh issue view *), Bash(git status), Bash(git diff *)
---

# New reusable workflow

The name is `$ARGUMENTS`. Read [docs/authoring-workflows.md](../../../docs/authoring-workflows.md) and [docs/testing.md](../../../docs/testing.md) first. They're the source of truth, and this skill only orders the steps.

## 1. Agree the name

- The name must be kebab-case `<domain>-<purpose>`, e.g. `node-ci` or `docker-publish`. It becomes a public file name and can't be renamed without a major release.
- Check that `.github/workflows/<name>.yml` doesn't exist yet.
- Look for the agreed proposal with `gh issue list --label new-workflow --search "<name>"`. If there's none, stop and ask the user whether to continue anyway. CONTRIBUTING.md asks for the name and contract to be agreed in an issue first.

## 2. Agree the contract

Write the contract down and get the user to confirm it before writing code. Use the same shape as the issue template's Contract field (`.github/ISSUE_TEMPLATE/new-workflow.yml`):

```
inputs: <name> (<type>, default <value>), working-directory (string, default ".")
outputs: <name>
secrets: <NAME> (required|optional)
permissions: contents:read, ...
```

Ask which catalog actions it uses and which third-party actions it needs. Pin any new third-party action with `/pin-action`.

## 3. Scaffold and implement

1. Run `make new-workflow NAME=<name>`. This creates `.github/workflows/<name>.yml`, `.github/workflows/_test-wf-<name>.yml` and `examples/callers/<name>.yml`, with pins already synced.
2. Implement `.github/workflows/<name>.yml` from the agreed contract. Replace the template's example output and step, and keep the header comment and the `.catalog` checkout if it uses catalog actions; delete that checkout if it doesn't.
3. Update `examples/callers/<name>.yml`: the permissions callers must grant, the `with:` inputs and the `secrets:` they pass.

## 4. Tests and fixtures

1. Add a minimal passing project under `tests/fixtures/<name>/`.
2. If the workflow should catch errors, add `tests/fixtures/<name>-failing/`. The failing call and its assert job go in `_ci.yml`, not the test workflow (see "Writing good tests" in docs/testing.md).
3. Replace the template assertions in `_test-wf-<name>.yml` with checks of the real outputs.

## 5. Register in `_ci.yml`

Follow "Register a component in `_ci.yml`" in docs/testing.md. Name the filter `wf-<name>` and the job `test-wf-<name>`.

- The filter covers the workflow, its test and both fixture directories, plus `actions/<x>/**` for every catalog action it uses.
- For a failing fixture, also add `test-wf-<name>-failing` and `test-wf-<name>-failing-assert`, and put only the assert job in `ci-ok.needs`. Give both `github.event_name != 'push'` in their `if:`, like the existing ones.

## 6. Docs

Replace the `_none yet_` row in the README Workflows table, or add a new row. Give the purpose, the permissions callers must grant, and a link to `examples/callers/<name>.yml`.

## 7. Check and hand over

1. Run `make lint` and fix every finding.
2. Run the `catalog-reviewer` agent on the change and fix what it reports.
3. Suggest the PR title `feat(<name>): add <name> workflow`, plus `Closes #<issue>` for the description. Don't commit or push unless the user asks.
