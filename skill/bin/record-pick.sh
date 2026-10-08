#!/usr/bin/env bash
# Record what was chosen in a picture session — exactly what was picked, never an interpretation.
# Usage:
#   record-pick.sh <subject> <card> <choice> [--how pointed|touched|said|looked|aac|tapped] [--prompt none|light|full] [--by NAME]
#       <choice> = the picture (emoji), its word, its number in the session, or "skip"
#   record-pick.sh <subject> --batch [--by NAME]  < pasted lines from the tap page ("pick <card> <key> <pos>/<n>")
# --prompt: none = their own choice · light = pointed/asked again · full = hand-over-hand (counted separately)
set -euo pipefail
. "$(dirname "$0")/_lib.sh"

S=""; CARD=""; CHOICE=""; HOW="pointed"; PROMPT="none"; BY=""; BATCH=0
pos=()
while [ $# -gt 0 ]; do
  case "$1" in
    --how)    HOW="${2:?}"; shift 2 ;;
    --prompt) PROMPT="${2:?}"; shift 2 ;;
    --by)     BY="${2:?}"; shift 2 ;;
    --batch)  BATCH=1; shift ;;
    -*)       die "unknown option $1" ;;
    *)        pos+=("$1"); shift ;;
  esac
done
S="${pos[0]:-}"; CARD="${pos[1]:-}"; CHOICE="${pos[2]:-}"
[ -n "$S" ] || die "usage: record-pick.sh <subject> <card> <choice> [--how H] [--prompt P] [--by NAME]"
check_name "$S"
case "$PROMPT" in none|light|full) ;; *) die "--prompt must be none, light or full" ;; esac
SESSION="$PICKS_DIR/.session-$S.tsv"
[ -f "$SESSION" ] || die "no session for $S (run picture-session.sh first)"
umask 077
PICKS="$PICKS_DIR/$S.tsv"
[ -f "$PICKS" ] || printf 'ts\tsession\tcard\tkey\tlabel\tpos\tn\thow\tprompt\tby\n' > "$PICKS"
TS="$(date '+%Y-%m-%d %H:%M')"

if [ "$BATCH" = 1 ]; then
  input="$(cat)"; HOW="tapped"
else
  [ -n "$CARD" ] && [ -n "$CHOICE" ] || die "need <card> and <choice>"
  input="pick $CARD $CHOICE"
fi

# Resolve each pick against the session (position, label), then append one TSV row.
TS="$TS" HOW="$HOW" PROMPT="$PROMPT" BY="$BY" INPUT="$input" awk -F'\t' '
  function low(s) { return tolower(s) }
  NR == 1 { sid = $2; next }
  { c = $1; n[c] = NF - 2; for (i = 3; i <= NF; i++) { o = $i; k = o; sub(/ .*/, "", k)
      l = o; if (index(o, " ")) sub(/^[^ ]+ /, "", l); else l = ""
      key[c, i - 2] = k; lab[c, i - 2] = l } }
  END {
    m = split(ENVIRON["INPUT"], lines, "\n")
    for (x = 1; x <= m; x++) {
      line = lines[x]; sub(/\r$/, "", line)
      if (line ~ /^session /) { s2 = substr(line, 9); if (s2 != sid) { print "record-pick: pasted session " s2 " is not the latest (" sid ")" > "/dev/stderr"; bad = 1; exit 1 } ; continue }
      if (line !~ /^pick /) continue
      rest = substr(line, 6); card = rest; sub(/ .*/, "", card); ch = rest; sub(/^[^ ]+ /, "", ch)
      pp = "-"; if (match(ch, / [0-9-]+\/[0-9]+$/)) { pp = substr(ch, RSTART + 1); ch = substr(ch, 1, RSTART - 1) }
      if (!(card in n)) { print "record-pick: card \"" card "\" was not in the last session" > "/dev/stderr"; bad = 1; continue }
      k = ""; l = ""; p = "-"
      if (low(ch) ~ /^(skip|none|pular|—|-)$/) { k = "—"; l = "skipped" }
      else for (i = 1; i <= n[card]; i++)
        if (ch == i "" || ch == key[card, i] || low(ch) == low(lab[card, i]) || low(ch) == low(key[card, i] " " lab[card, i])) { k = key[card, i]; l = lab[card, i]; p = i; break }
      if (k == "") { print "record-pick: \"" ch "\" is not an option on card " card > "/dev/stderr"; bad = 1; continue }
      if (pp != "-" && k != "—") p = pp; else if (k != "—") p = p "/" n[card]; else p = "-"
      split(p, pq, "/")
      printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", ENVIRON["TS"], sid, card, k, l, pq[1], (pq[2] == "" ? "-" : pq[2]), ENVIRON["HOW"], ENVIRON["PROMPT"], ENVIRON["BY"] >> PICKS
      ok++
    }
    if (ok) printf "recorded %d pick%s for %s\n", ok, (ok > 1 ? "s" : ""), S
    exit bad
  }' PICKS="$PICKS" S="$S" "$SESSION"
