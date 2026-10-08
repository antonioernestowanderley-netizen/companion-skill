#!/usr/bin/env bash
# Honest counts for the learning loop: every question asked, and how it landed.
# Reads "Asked → answered" lines from the ledger. ✓ answered · ~ partial · ✗ no answer / distress
# Usage: question-stats.sh            (all time, plus since the last "### Review" entry)
set -euo pipefail
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LEDGER="$SKILL_DIR/interaction-ledger.md"
[ -f "$LEDGER" ] || { echo "question-stats: no ledger" >&2; exit 1; }

awk '
  index($0, "<!-- newest first -->") { started = 1; next }   # skip the template above the entries
  !started { next }
  /^### [0-9-]+ ?[0-9:]* *— *[Rr]eview|^### [Rr]eview/ { if (!rev) rev = $0; seen_review = 1 }  # newest first: first review seen is the latest
  /\*\*Asked → answered:\*\*/ {
    line = $0; sub(/.*\*\*Asked → answered:\*\*[ \t]*/, "", line)
    q = line; if (match(q, /^"[^"]*"/)) q = substr(q, RSTART + 1, RLENGTH - 2); else { sub(/ → .*/, "", q) }
    r = "?"; if (index(line, "→ ✓")) r = "✓"; else if (index(line, "→ ~")) r = "~"; else if (index(line, "→ ✗")) r = "✗"
    if (!(q in n)) order[++k] = q
    n[q]++; c[q, r]++; if (!seen_review) { recent[q]++; total_recent++ }
    total++
  }
  END {
    if (!total) { print "No questions logged yet. Log them with: log-moment.sh --asked \"…\" --result yes|partial|no"; exit }
    printf "%d questions logged · %d since last review%s\n\n", total, total_recent, (rev ? " (" rev ")" : " (no review yet)")
    print "  ✓    ~    ✗   new    question"
    for (i = 1; i <= k; i++) { q = order[i]
      tag = ""
      if (c[q, "✓"] >= 2 && !c[q, "✗"]) tag = "  → promote: Lands ✓"
      else if (c[q, "✗"] >= 2) tag = "  → move: Doesn'\''t land ✗"
      printf "%3d  %3d  %3d   %-5s  %s%s\n", c[q, "✓"], c[q, "~"], c[q, "✗"], (recent[q] ? "+" recent[q] : ""), q, tag }
  }' "$LEDGER"
