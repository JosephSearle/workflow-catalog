#!/usr/bin/env bash
# Installs a pinned, hash-checked gitleaks and scans the full Git history of
# the repo in GITHUB_WORKSPACE. Writes result=success|failure|error, and
# exits non-zero on error, or on findings when FAIL_ON_FINDINGS is true.
set -euo pipefail

# Dependabot can't bump these. To upgrade, pick a release at least 7 days old
# and take the hashes from its checksums.txt.
GITLEAKS_VERSION=8.30.1
GITLEAKS_SHA256_X64=551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb
GITLEAKS_SHA256_ARM64=e4a487ee7ccd7d3a7f7ec08657610aa3606637dab924210b3aee62570fb4b080

result=""
# Anything that exits before a result is set (a failed download, a bad
# hash) counts as an error, so the result output is always set.
trap 'if [ -z "$result" ]; then echo "result=error" >> "$GITHUB_OUTPUT"; fi' EXIT

error() {
  echo "::error::$1"
  result=error
  echo "result=error" >> "$GITHUB_OUTPUT"
  exit 1
}

if [ "$RUNNER_OS" != Linux ]; then
  error "scan-secrets runs on Linux runners only, got $RUNNER_OS."
fi
case "$RUNNER_ARCH" in
  X64) arch=x64 sha="$GITLEAKS_SHA256_X64" ;;
  ARM64) arch=arm64 sha="$GITLEAKS_SHA256_ARM64" ;;
  *) error "scan-secrets supports X64 and ARM64 runners, got $RUNNER_ARCH." ;;
esac
case "$FAIL_ON_FINDINGS" in
  true|false) ;;
  *) error "fail-on-findings must be 'true' or 'false', got '$FAIL_ON_FINDINGS'." ;;
esac

# Install before checking the repo and config, so gitleaks is on PATH for
# later steps (e.g. pre-commit hooks) even when the scan can't run.
file="gitleaks_${GITLEAKS_VERSION}_linux_$arch.tar.gz"
bin="$RUNNER_TEMP/scan-secrets-bin"
mkdir -p "$bin"
curl -fsSL --retry 3 -o "$RUNNER_TEMP/$file" "https://github.com/gitleaks/gitleaks/releases/download/v$GITLEAKS_VERSION/$file"
(cd "$RUNNER_TEMP" && printf '%s  %s\n' "$sha" "$file" | sha256sum -c -)
tar -xzf "$RUNNER_TEMP/$file" -C "$bin" gitleaks
echo "$bin" >> "$GITHUB_PATH"
"$bin/gitleaks" version
echo "gitleaks-version=$GITLEAKS_VERSION" >> "$GITHUB_OUTPUT"

# A shallow clone would quietly scan only the fetched commits.
if ! shallow="$(git rev-parse --is-shallow-repository 2>/dev/null)"; then
  error "'$GITHUB_WORKSPACE' isn't a Git repository. Check out the repo first."
fi
if [ "$shallow" = true ]; then
  error "The checkout is shallow, so the scan would miss older commits. Set fetch-depth: 0 on actions/checkout."
fi

args=(git --no-banner --redact --exit-code 2)
if [ -n "$CONFIG" ]; then
  if [ ! -f "$CONFIG" ]; then
    error "config '$CONFIG' doesn't exist."
  fi
  args+=(--config "$CONFIG")
fi

# Leaks exit 2, so they can be told apart from gitleaks errors (exit 1).
status=0
"$bin/gitleaks" "${args[@]}" . || status=$?
case "$status" in
  0) result=success ;;
  2) result=failure ;;
  *) error "gitleaks failed (exit $status). Check the config and the log above." ;;
esac
echo "result=$result" >> "$GITHUB_OUTPUT"

if [ "$result" = failure ]; then
  message="gitleaks found secrets in the Git history. Rotate them, then list their fingerprints in .gitleaksignore."
  if [ "$FAIL_ON_FINDINGS" = true ]; then
    echo "::error::$message"
    exit 1
  fi
  echo "::warning::$message Not failing because fail-on-findings is false."
fi
