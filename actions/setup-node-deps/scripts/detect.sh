#!/usr/bin/env bash
# Detects the package manager, lockfile and Node version for setup-node-deps.
# Runs in working-directory. Setup actions take paths relative to the repo
# root, so it emits root-relative paths alongside the package manager and
# Node version.
set -euo pipefail

dir="${WORKING_DIRECTORY%/}"

# Walk up from working-directory to the repo root and take the first
# lockfile, so workspace members use the workspace root's lockfile.
root="$(cd "$GITHUB_WORKSPACE" && pwd -P)"
search="$(pwd -P)"
pm=""
while :; do
  if [ -f "$search/pnpm-lock.yaml" ]; then
    pm=pnpm lockfile=pnpm-lock.yaml
    break
  elif [ -f "$search/package-lock.json" ]; then
    pm=npm lockfile=package-lock.json
    break
  fi
  if [ "$search" = "$root" ] || [ "$search" = / ]; then
    break
  fi
  search="$(dirname "$search")"
done
if [ -z "$pm" ]; then
  echo "::error::No pnpm-lock.yaml or package-lock.json in '$WORKING_DIRECTORY' or any parent up to the repo root. Commit a lockfile."
  exit 1
fi
# Root-relative directory holding the lockfile, "." at the repo root.
lock_dir="${search#"$root"}"
lock_dir="${lock_dir#/}"
lock_dir="${lock_dir:-.}"

# pnpm/action-setup gets no version input, so it needs packageManager.
if [ "$pm" = pnpm ] && ! grep -Eq '"packageManager"[[:space:]]*:[[:space:]]*"pnpm@' "$search/package.json"; then
  echo "::error::pnpm-lock.yaml found in '$lock_dir', but its package.json has no \"packageManager\": \"pnpm@<version>\" field. Add one."
  exit 1
fi

# A lockfile from a parent only counts if that parent is a workspace
# root. Otherwise the package's own dependencies would never install.
if [ "$search" != "$(pwd -P)" ]; then
  not_root=""
  if [ "$pm" = pnpm ] && [ ! -f "$search/pnpm-workspace.yaml" ]; then
    not_root="no pnpm-workspace.yaml"
  elif [ "$pm" = npm ] && ! grep -Eq '"workspaces"[[:space:]]*:' "$search/package.json"; then
    not_root="no \"workspaces\" in its package.json"
  fi
  if [ -n "$not_root" ]; then
    echo "::error::No lockfile in '$WORKING_DIRECTORY', and '$lock_dir/$lockfile' isn't a workspace root ($not_root). Commit a lockfile."
    exit 1
  fi
  echo "::notice::Using the workspace lockfile $lock_dir/$lockfile."
fi

# Look in working-directory, then the workspace root, then the repo root.
version="$NODE_VERSION" version_file="" source="node-version input"
if [ -z "$version" ]; then
  for candidate in "$dir/.nvmrc" "$dir/.node-version" "$lock_dir/.nvmrc" "$lock_dir/.node-version" .nvmrc .node-version; do
    if [ -f "$GITHUB_WORKSPACE/$candidate" ]; then
      version_file="$candidate" source="$candidate"
      break
    fi
  done
  if [ -z "$version_file" ]; then
    version="lts/*" source="default (no .nvmrc or .node-version found)"
  fi
fi
echo "::notice::Node version from $source."

{
  echo "package-manager=$pm"
  echo "lock-dir=$lock_dir"
  echo "lockfile=$lock_dir/$lockfile"
  echo "package-json=$lock_dir/package.json"
  echo "node-version=$version"
  echo "node-version-file=$version_file"
} >> "$GITHUB_OUTPUT"
