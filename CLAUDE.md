# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

@AGENTS.md

## Claude Code tooling

Project config lives in `.claude/`:

- **Skills:** `/new-workflow <name>`, `/new-action <name>` and `/pin-action <owner/repo>@<vX.Y.Z>` guide the authoring steps that `make new-*` doesn't do: the contract, fixtures, `_ci.yml` registration, docs and pinning.
- **Agent:** `catalog-reviewer` reviews the diff against `main` for security rules, semver impact and missing registration or docs. Run it before suggesting a PR.
- **Hook:** after each edit to a workflow, action or template, `.claude/hooks/lint-edited.sh` runs `make lint-files` on that file. If it reports findings, fix them before moving on.
- **Rules:** `.claude/rules/` loads short versions of the authoring guides when matching paths are touched.
