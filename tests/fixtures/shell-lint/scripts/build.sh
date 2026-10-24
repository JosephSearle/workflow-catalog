#!/bin/sh
# Clean apart from SC2034, which .shellcheckrc disables.
set -eu

unused_example="kept to trigger SC2034"
out_dir="${1:-dist}"
mkdir -p "$out_dir"
echo "built into $out_dir"
