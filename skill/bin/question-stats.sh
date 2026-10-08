#!/usr/bin/env bash
# Honest counts for the learning loop: every question asked, and how it landed.
# Reads "Asked → answered" lines from the ledger. ✓ answered · ~ partial · ✗ no answer / distress
# Usage: question-stats.sh            (all time, plus what's new since the last review)
set -euo pipefail
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LEDGER="$SKILL_DIR/interaction-ledger.md"
[ -f "$LEDGER" ] || { echo "question-stats: no ledger" >&2; exit 1; }

awk '
  function key(s) { s = tolower(s); gsub(/[ \t]+/, " ", s); sub(/^[ "]+/, "", s); sub(/[ ?!.,"]+$/, "", s); return s }
  index($0, "<!-- newest first -->") { started = 1; next }   # skip the template above the entries
  !started { next }
  /^### [0-9-]+ ?[0-9:]* *— *[Rr]eview|^### [Rr]eview/ { if (!rev) rev = $0; seen_review = 1; next }  # newest first: the first review seen is the latest
  /\*\*Asked → answered:\*\*/ {
    line = $0; sub(/.*\*\*Asked → answered:\*\*[ \t]*/, "", line)
    r = "?"; q = line
    if (substr(line, 1, 1) == "\"" && match(line, /" → (✓|~|✗)/)) {             # "question" → ✓ "answer"
      q = substr(line, 2, RSTART - 2); m = substr(line, RSTART, RLENGTH)
    } else { sub(/ → .*/, "", q); m = line }                                      # hand-written, no quotes
    if (index(m, "→ ✓")) r = "✓"; else if (index(m, "→ ~")) r = "~"; else if (index(m, "→ ✗")) r = "✗"
    k = key(q); if (!(k in n)) order[++nk] = k; shown[k] = q          # newest first, so this ends on the original wording
    n[k]++; c[k, r]++; if (!seen_review) { recent[k]++; total_recent++ }
    total++
  }
  END {
    if (!total) { print "No questions logged yet. Log them with: log-moment.sh --asked \"…\" --result yes|partial|no"; exit }
    printf "%d questions logged · %d since last review%s\n\n", total, total_recent, (rev ? " (" rev ")" : " (no review yet)")
    print "  ✓    ~    ✗   new    question"
    for (i = 1; i <= nk; i++) { k = order[i]; y = c[k, "✓"] + 0; x = c[k, "✗"] + 0
      tag = ""
      if (y >= 2 && !x) tag = "  → promote: Lands ✓"
      else if (x >= 2 && !y) tag = "  → move: Doesn'\''t land ✗"
      else if (y && x) tag = "  → mixed: compare context and state"
      printf "%3d  %3d  %3d   %-5s  %s%s\n", y, c[k, "~"], x, (recent[k] ? "+" recent[k] : ""), shown[k], tag }
  }' "$LEDGER"
