#!/usr/bin/env bash
# Installs a pinned, hash-checked shellcheck and runs it on the shell scripts
# under WORKING_DIRECTORY. Writes result=success|failure|error|skipped and
# files=<checked scripts>, and exits non-zero on error, or on findings when
# FAIL_ON_FINDINGS is true.
set -euo pipefail

# Dependabot can't bump these. To upgrade, pick a release at least 7 days old,
# then take the hashes from the release assets' digests (`gh api
# repos/koalaman/shellcheck/releases/tags/<tag> -q '.assets[].digest'`).
SHELLCHECK_VERSION=v0.11.0
SHELLCHECK_SHA256_X64=8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198
SHELLCHECK_SHA256_ARM64=12b331c1d2db6b9eb13cfca64306b1b157a86eb69db83023e261eaa7e7c14588

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
  error "lint-shell runs on Linux runners only, got $RUNNER_OS."
fi
case "$RUNNER_ARCH" in
  X64) arch=x86_64 sha="$SHELLCHECK_SHA256_X64" ;;
  ARM64) arch=aarch64 sha="$SHELLCHECK_SHA256_ARM64" ;;
  *) error "lint-shell supports X64 and ARM64 runners, got $RUNNER_ARCH." ;;
esac
case "$FAIL_ON_FINDINGS" in
  true|false) ;;
  *) error "fail-on-findings must be 'true' or 'false', got '$FAIL_ON_FINDINGS'." ;;
esac

# Install before checking working-directory, so shellcheck is on PATH for
# later steps (e.g. pre-commit hooks) even when the lint can't run.
file="shellcheck-$SHELLCHECK_VERSION.linux.$arch.tar.xz"
bin="$RUNNER_TEMP/lint-shell-bin"
mkdir -p "$bin"
curl -fsSL --retry 3 -o "$RUNNER_TEMP/$file" "https://github.com/koalaman/shellcheck/releases/download/$SHELLCHECK_VERSION/$file"
(cd "$RUNNER_TEMP" && printf '%s  %s\n' "$sha" "$file" | sha256sum -c -)
tar -xJf "$RUNNER_TEMP/$file" --strip-components=1 -C "$bin" "shellcheck-$SHELLCHECK_VERSION/shellcheck"
echo "$bin" >> "$GITHUB_PATH"
"$bin/shellcheck" --version
echo "shellcheck-version=$SHELLCHECK_VERSION" >> "$GITHUB_OUTPUT"

if ! cd -- "$WORKING_DIRECTORY" 2>/dev/null; then
  error "working-directory '$WORKING_DIRECTORY' doesn't exist."
fi

# Checks *.sh and *.bash files, plus any other file with a sh, bash, dash or
# ksh shebang. Skips .git, dependency directories and the catalog checkout
# that catalog workflows put at the repo root.
shebang='^#![[:space:]]*/[^[:space:]]*/(env[[:space:]]+(-S[[:space:]]+)?)?(sh|bash|dash|ksh)([[:space:]]|$)'
files=()
while IFS= read -r -d '' f; do
  f="${f#./}"
  if [[ "$f" == *$'\n'* ]]; then
    echo "::warning::Skipping a file whose name contains a newline."
    continue
  fi
  case "$f" in
    *.sh|*.bash) files+=("$f") ;;
    *)
      if head -n 1 -- "$f" 2>/dev/null | grep -Eq "$shebang"; then
        files+=("$f")
      fi
      ;;
  esac
done < <(find . \( -name .git -o -name node_modules -o -name .venv -o -path ./.catalog \) -prune -o -type f -print0 | sort -z)

echo "files=${files[*]}" >> "$GITHUB_OUTPUT"
if [ "${#files[@]}" -eq 0 ]; then
  echo "::notice::No shell scripts found, so shellcheck was skipped."
  result=skipped
  echo "result=$result" >> "$GITHUB_OUTPUT"
  exit 0
fi
echo "Checking ${#files[@]} file(s):"
printf '  %s\n' "${files[@]}"

# The caller's .shellcheckrc is read by shellcheck itself, which also follows
# `source` to files it can find next to the script. Exit 1 means findings.
# Anything else is shellcheck itself failing.
status=0
"$bin/shellcheck" --external-sources --source-path=SCRIPTDIR -- "${files[@]}" || status=$?
case "$status" in
  0) result=success ;;
  1) result=failure ;;
  *) error "shellcheck failed (exit $status). Check .shellcheckrc and the log above." ;;
esac
echo "result=$result" >> "$GITHUB_OUTPUT"

if [ "$result" = failure ]; then
  message="shellcheck found problems in the scripts above."
  if [ "$FAIL_ON_FINDINGS" = true ]; then
    echo "::error::$message"
    exit 1
  fi
  echo "::warning::$message Not failing because fail-on-findings is false."
fi
