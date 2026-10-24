#!/bin/sh
# Claude Code PostToolUse hook. After Claude edits a workflow, action or template,
# lints just that file with `make lint-files` and, on findings, exits 2 so Claude
# sees them and fixes them. It never blocks the edit itself.
#
# Input: the hook event JSON on stdin. Other files exit 0 silently.
set -eu

root=${CLAUDE_PROJECT_DIR:-$(pwd)}

# python3 is already needed by pre-commit, so this adds no jq dependency.
path=$(python3 -c 'import json, sys; print(json.load(sys.stdin).get("tool_input", {}).get("file_path", ""))')

case "$path" in
  "$root"/*) rel=${path#"$root"/} ;;
  *) exit 0 ;;
esac

# A coarse filter. `make lint-files` validates the path strictly before using it.
case "$rel" in
  .github/workflows/*.yml | .github/workflows/*.yaml | actions/*/action.yml | actions/*/action.yaml | templates/*.yml) ;;
  *) exit 0 ;;
esac

if ! out=$(make -s -C "$root" lint-files FILES="$rel" 2>&1); then
  printf 'Lint findings in %s. Fix them before moving on:\n%s\n' "$rel" "$out" >&2
  exit 2
fi
