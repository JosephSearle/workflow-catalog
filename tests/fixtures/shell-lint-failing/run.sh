#!/bin/sh
# Fails shellcheck: unquoted "$1" (SC2086).
set -eu

cp $1 "${2:-.}"
