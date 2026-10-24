#!/bin/sh
# Keeps action pins in step with the live pins in .github/workflows and actions/,
# which Dependabot keeps current. It can't scan templates/, so `make new-*` syncs
# each scaffolded file, and stale template pins never reach a new component.
#
# Usage: scripts/template-pins.sh --check [FILE...]   Fail if a pin is behind the live pin.
#        scripts/template-pins.sh --sync [FILE...]    Rewrite pins (and their # comments) to the live pins.
#
# FILE defaults to every file under templates/. The given files never count as live.
# Only live `uses:` lines count: commented-out pins are ignored on both sides.
# Actions no live file uses have nothing to sync to, so they're left alone.
set -eu

case "${1:-}" in
  --check | --sync) mode=${1#--}; shift ;;
  *) echo "Usage: $0 --check | --sync [FILE...]" >&2; exit 2 ;;
esac

if [ "$#" -gt 0 ]; then
  targets=$(printf '%s ' "$@")
else
  targets=$(find templates -type f \( -name '*.yml' -o -name '*.yaml' \) | sort | tr '\n' ' ')
fi
[ -n "$targets" ] || exit 0

live=
for f in $(find .github/workflows actions -type f \( -name '*.yml' -o -name '*.yaml' \) 2>/dev/null | sort); do
  case " $targets" in *" $f "*) ;; *) live="$live $f" ;; esac
done

# Reads live files until `tmpl=1`, then checks or rewrites each target line into
# FILENAME.tmp, and prints the names of the files it changed.
# Parses `uses: owner/repo[/path]@<40-hex sha> # comment`, quoted or not.
# Exits 4 if a pin is stale (check) or can't be resolved (sync).
# shellcheck disable=SC2016
prog='
function parse(line,   s, at) {
  if (line !~ /^[ \t]*(-[ \t]+)?uses:[ \t]/) return 0
  s = line
  sub(/^[ \t]*(-[ \t]+)?uses:[ \t]+/, "", s)
  comment = ""
  if (match(s, /[ \t]+#.*$/)) { comment = substr(s, RSTART); s = substr(s, 1, RSTART - 1) }
  gsub(/["\047]/, "", s)
  at = index(s, "@")
  if (at < 2 || substr(s, 1, 1) == ".") return 0
  action = substr(s, 1, at - 1); sha = substr(s, at + 1)
  return length(sha) == 40 && sha ~ /^[0-9a-f]+$/
}
!tmpl {
  if (parse($0)) {
    pinned[action, sha] = 1
    if (!(action in pin)) { pin[action] = sha; note[action] = comment }
    else if (pin[action] != sha) ambiguous[action] = 1
  }
  next
}
FNR == 1 { if (out != "") close(out); out = FILENAME ".tmp" }
{
  line = $0
  if (parse(line) && (action in pin) && !((action, sha) in pinned)) {
    if (mode == "check" || (action in ambiguous)) {
      print "  " FILENAME ":" FNR ": " action "@" sha > "/dev/stderr"
      bad = 1
    } else {
      line = substr(line, 1, length(line) - length(comment))
      i = index(line, sha)
      line = substr(line, 1, i - 1) pin[action] substr(line, i + 40) note[action]
      changed[FILENAME] = 1
    }
  }
  if (mode == "sync") print line > out
}
END {
  for (f in changed) print f
  exit bad ? 4 : 0
}
'

rc=0
# shellcheck disable=SC2086 # $live and $targets are word-split lists of repo paths.
changed=$(awk -v mode="$mode" "$prog" $live tmpl=1 $targets) || rc=$?

if [ "$rc" -eq 0 ] || [ "$rc" -eq 4 ]; then
  for f in $changed; do mv "$f.tmp" "$f"; echo "Updated pins in $f."; done
fi
for f in $targets; do rm -f "$f.tmp"; done

case "$rc" in
  0) ;;
  4)
    if [ "$mode" = check ]; then
      echo "These pins are behind the live pins in .github/workflows or actions/. Run 'make sync-template-pins'." >&2
      exit 1
    fi
    # Warn only, so scaffolding still finishes.
    echo "These pins match none of their action's live pins, which disagree with each other. Update them by hand." >&2
    ;;
  *) echo "awk failed (exit $rc), so no pins were checked or changed." >&2; exit 2 ;;
esac
