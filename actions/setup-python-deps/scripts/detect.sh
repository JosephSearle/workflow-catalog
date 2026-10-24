#!/usr/bin/env bash
# Finds uv.lock and reports where the Python version comes from, for
# setup-python-deps. Runs in working-directory. setup-uv may resolve relative
# globs against its working-directory, so it emits an absolute lockfile path,
# plus the root-relative lock-dir for callers.
set -euo pipefail

if [ ! -f pyproject.toml ]; then
  echo "::error::No pyproject.toml in '$WORKING_DIRECTORY'."
  exit 1
fi

# Walk up from working-directory to the repo root, as uv does for
# workspaces, and take the first uv.lock.
root="$(cd "$GITHUB_WORKSPACE" && pwd -P)"
search="$(pwd -P)"
lockfile=""
while :; do
  if [ -f "$search/uv.lock" ]; then
    lockfile="$search/uv.lock"
    break
  fi
  if [ "$search" = "$root" ] || [ "$search" = / ]; then
    break
  fi
  search="$(dirname "$search")"
done
if [ -z "$lockfile" ]; then
  echo "::error::No uv.lock in '$WORKING_DIRECTORY' or any parent up to the repo root. Run 'uv lock' and commit it."
  exit 1
fi
# Root-relative directory holding uv.lock, "." at the repo root.
lock_dir="${search#"$root"}"
lock_dir="${lock_dir#/}"
lock_dir="${lock_dir:-.}"

if [ -n "$PYTHON_VERSION" ]; then
  echo "::notice::Python version from the python-version input."
elif [ -f .python-version ]; then
  echo "::notice::Python version from $WORKING_DIRECTORY/.python-version."
else
  echo "::notice::No .python-version in '$WORKING_DIRECTORY', so uv checks parent directories, then requires-python."
fi

{
  echo "lockfile=$lockfile"
  echo "lock-dir=$lock_dir"
} >> "$GITHUB_OUTPUT"
