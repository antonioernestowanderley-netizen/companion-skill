#!/usr/bin/env bash
# Capture a moment into the shared ledger — newest-first, atomic, never loses text.
# Usage: log-moment.sh [--by NAME] "free text of the moment"
set -euo pipefail
. "$(dirname "$0")/_lib.sh"

BY=""
if [ "${1:-}" = "--by" ]; then BY="${2:-}"; shift 2 2>/dev/null || shift $#; fi
TEXT="${*:-}"
[ -n "$TEXT" ] || die "no text given"
LEDGER="$DATA/ledger.md"
[ -f "$LEDGER" ] || die "no ledger at $LEDGER (run bin/init.sh first)"

TS="$(date '+%Y-%m-%d %H:%M %z')"
tmp="$(mktemp "$LEDGER.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

# Text travels via ENVIRON and is printed literally — no regex or $-substitution can mangle it.
TS="$TS" BY="$BY" TEXT="$TEXT" awk '
  BEGIN {
    t = ENVIRON["TEXT"]; gsub(/\r/, "", t); gsub(/\n/, "\n  ", t)
    hdr = "### " ENVIRON["TS"] " — quick capture"
    if (ENVIRON["BY"] != "") hdr = hdr "  (by: " ENVIRON["BY"] ")"
    entry = hdr "\n- **Raw note:** " t "\n- **Tags:** _untagged_\n"
  }
  { print }
  !done && index($0, "<!-- newest first -->") { print ""; printf "%s", entry; done = 1 }
  END { if (!done) { print ""; printf "%s", entry } }
' "$LEDGER" > "$tmp"

mv -f "$tmp" "$LEDGER"
trap - EXIT
echo "logged: $TS${BY:+ (by $BY)}"
