---
name: new-action
description: Scaffold, implement, test and register a new composite action in this catalog, following docs/authoring-actions.md and docs/testing.md. Use when someone wants to add an action or pull shared workflow steps into one, e.g. "add a setup-node-cached action".
argument-hint: <verb-noun>
allowed-tools: Read, Grep, Glob, Edit, Write, Bash(make new-action *), Bash(make lint), Bash(make lint-files *), Bash(gh issue list *), Bash(gh issue view *), Bash(git status), Bash(git diff *)
---

# New action

The name is `$ARGUMENTS`. Read [docs/authoring-actions.md](../../../docs/authoring-actions.md) and [docs/testing.md](../../../docs/testing.md) first. They're the source of truth, and this skill only orders the steps.

## 1. Check that it should be an action

An action is only for steps that two or more workflows share. Ask the user which two workflows will use it, existing or planned. If there's only one, recommend keeping the steps inline in that workflow and stop unless they insist.

## 2. Agree the name and contract

- The name must be kebab-case `<verb-noun>`, e.g. `setup-node-cached`. It's public API: consumers can reference `actions/<name>` directly.
- Check that `actions/<name>/` doesn't exist yet.
- Look for the agreed proposal with `gh issue list --label new-action --search "<name>"`. If there's none, stop and ask the user whether to continue anyway.
- Confirm the inputs (with descriptions and defaults), the outputs and the supported runners with the user.

## 3. Scaffold and implement

1. Run `make new-action NAME=<name>`. This creates `actions/<name>/action.yml`, `actions/<name>/README.md` and `.github/workflows/_test-action-<name>.yml`.
2. Implement `action.yml` as a composite action. Every `run` step sets `shell:`, inputs reach scripts through `env:`, and scripts over ~20 lines go in `actions/<name>/scripts/`. Don't call other catalog actions from it. Pin any new third-party action with `/pin-action`.
3. Fill in the README: usage, the inputs and outputs tables, and supported runners.

## 4. Tests

1. Replace the template assertions in `_test-action-<name>.yml` with checks of the real outputs and side effects.
2. Add a failure-path step: run the action with bad input and `continue-on-error: true`, then assert `steps.<id>.outcome == 'failure'`.
3. Set the OS matrix to the runners the README claims, and no others.

## 5. Register in `_ci.yml`

Follow "Register a component in `_ci.yml`" in docs/testing.md. Name the filter `action-<name>` and the job `test-action-<name>`. Also add `actions/<name>/**` to the filter of every workflow that uses the action.

## 6. Docs

List the action in `actions/README.md` and the README Actions table, replacing the `_none yet_` row if it's still there.

## 7. Check and hand over

1. Run `make lint` and fix every finding.
2. Run the `catalog-reviewer` agent on the change and fix what it reports.
3. Suggest the PR title `feat(<name>): add <name> action`. Don't commit or push unless the user asks.
