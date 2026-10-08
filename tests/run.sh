#!/usr/bin/env bash
# Smoke tests for the shell tools. Run: bash tests/run.sh
set -euo pipefail
BIN="$(cd "$(dirname "$0")/../skill/bin" && pwd)"
export COMPANION_DATA="$(mktemp -d)/data"
trap 'rm -rf "$(dirname "$COMPANION_DATA")"' EXIT
pass=0
ok()   { pass=$((pass+1)); echo "  ok  $*"; }
fail() { echo "  FAIL $*" >&2; exit 1; }

"$BIN/init.sh" Sam Maya >/dev/null
for f in pair ledger shared portraits/Sam-by-Sam portraits/Sam-by-Maya portraits/Maya-by-Maya portraits/Maya-by-Sam; do
  [ -f "$COMPANION_DATA/$f.md" ] || fail "init missing $f.md"
done
grep -q '^kind: self' "$COMPANION_DATA/portraits/Maya-by-Maya.md" && grep -q '^kind: seen' "$COMPANION_DATA/portraits/Maya-by-Sam.md" || fail "portrait kinds"
! grep -q '{{' "$COMPANION_DATA"/portraits/*.md "$COMPANION_DATA/pair.md" || fail "unrendered {{placeholders}}"
ok "init creates pair, ledger, shared and four portraits"

"$BIN/init.sh" Sam Maya >/dev/null 2>&1 && fail "init overwrote existing data" || ok "init refuses to overwrite"
"$BIN/init.sh" "a b" c >/dev/null 2>&1 && fail "accepted bad name" || ok "init rejects bad names"

"$BIN/log-moment.sh" --by Sam 'she said "I want $& and $$ \1 now"' >/dev/null
grep -qF 'she said "I want $& and $$ \1 now"' "$COMPANION_DATA/ledger.md" || fail "special chars mangled"
ok "log keeps \$&, \$\$ and backslashes literally"

"$BIN/log-moment.sh" "$(printf 'line one\nline two')" >/dev/null
first=$(grep -m1 -n 'quick capture' "$COMPANION_DATA/ledger.md" | cut -d: -f1)
marker=$(grep -n 'newest first' "$COMPANION_DATA/ledger.md" | cut -d: -f1)
[ "$first" -gt "$marker" ] && grep -q '^  line two' "$COMPANION_DATA/ledger.md" || fail "newest-first / multiline"
[ "$(grep -c 'quick capture' "$COMPANION_DATA/ledger.md")" = 2 ] || fail "entry count"
ok "log is newest-first, keeps multiline text, loses nothing"

"$BIN/log-moment.sh" >/dev/null 2>&1 && fail "empty log accepted" || ok "log refuses empty text"

P="$COMPANION_DATA/portraits"
sed -i.bak 's/^- Processing time needed:$/- Processing time needed: lots — count to ten/' "$P/Maya-by-Maya.md"
sed -i.bak 's/^- Processing time needed:$/- Processing time needed: she answers fast/' "$P/Maya-by-Sam.md"
out=$("$BIN/side-by-side.sh" Maya Maya)
grep -q 'count to ten' <<<"$out" && ! grep -q 'answers fast' <<<"$out" || fail "visibility: private witness view leaked"
ok "side-by-side hides portraits not shared with the viewer"

sed -i.bak 's/^visible-to: author-only/visible-to: both/' "$P/Maya-by-Sam.md"
out=$("$BIN/side-by-side.sh" Maya Maya)
grep -q 'answers fast' <<<"$out" && grep -q '### seen by Sam' <<<"$out" || fail "shared witness view missing"
awk '/### self/{s=NR} /### seen by Sam/{w=NR} END{exit !(s<w)}' <<<"$out" || fail "self should come first"
! grep -qE 'Getting things across|idioms OK\?' <<<"$out" || fail "blank stubs shown"
ok "side-by-side shows shared views, self first, blanks hidden"

# ── picture-choice self-portrait ─────────────────────────────────
export COMPANION_SEED=11
SESS="$COMPANION_DATA/picks/.session-Maya.tsv"
"$BIN/picture-session.sh" Maya --n 3 >/dev/null
[ "$(sed -n 2p "$SESS" | cut -f1)" = feel-now ] && [ "$(grep -vc '^#' "$SESS")" = 4 ] || fail "session: warm-up first + 3 cards"
[ -f "$COMPANION_DATA/cards.md" ] || fail "deck not copied to data/"
grep -q $'\tI want Sam to' "$COMPANION_DATA/picks/.session-Maya.tsv" || "$BIN/picture-session.sh" Maya --cards wish >/dev/null
grep -q $'\tI want Sam to' "$SESS" || fail "{{OTHER}} not filled with the other person's name"
ok "picture session: warm-up first, N cards, other person's name filled in"

"$BIN/picture-session.sh" Maya --cards loud,wish >/dev/null
"$BIN/record-pick.sh" Maya loud 😣 --by Sam >/dev/null
"$BIN/record-pick.sh" Maya wish "go slower" --by Sam >/dev/null
"$BIN/record-pick.sh" Maya loud skip >/dev/null
n=$(awk -F'\t' '$4=="😣"{print $6}' "$COMPANION_DATA/picks/Maya.tsv")
[ "$(awk -F'\t' -v k="$n" '$1=="loud"{split($0,a,"\t"); print a[k+2]}' "$SESS")" = "😣 bad" ] || fail "position of the pick not recorded correctly"
grep -q $'\twish\t🐢\tgo slower\t' "$COMPANION_DATA/picks/Maya.tsv" && grep -q $'\tloud\t—\tskipped\t' "$COMPANION_DATA/picks/Maya.tsv" || fail "word / skip"
"$BIN/record-pick.sh" Maya loud banana >/dev/null 2>&1 && fail "accepted a choice that is not on the card"
ok "record-pick: by picture, word, skip; records shown position; rejects non-options"

printf 'session 1999-01-01 00:00\npick loud 😣 1/3\n' | "$BIN/record-pick.sh" Maya --batch >/dev/null 2>&1 && fail "accepted a stale pasted session"
sid=$(head -1 "$SESS" | cut -f2)
printf 'session %s\npick loud 😣 3/3\npick wish 🧩 1/3\n' "$sid" | "$BIN/record-pick.sh" Maya --batch --by Sam | grep -q 'recorded 2' || fail "batch paste"
ok "record-pick --batch: takes the tap page's paste, refuses a stale one"

T="$COMPANION_DATA/picks/Maya.tsv"
printf '%s\n' "2026-01-02 10:00	s2	loud	😣	bad	2	3	pointed	none	Ana" >> "$T"
sumr=$("$BIN/picks-summary.sh" Maya)
grep -q 'loud .*😣 bad 3/3 · 2 days — STEADY' <<<"$sumr" || fail "STEADY after 3 picks on 2 days: $sumr"
grep -q 'wish .*EMERGING' <<<"$sumr" && grep -q 'skipped ×1' <<<"$sumr" || fail "EMERGING / skips"
! grep -q 'feel-now' <<<"$sumr" || fail "warm-up should not appear in the summary"
ok "picks-summary: STEADY needs 3+ answers on 2+ days; skips shown; warm-up excluded"

for i in 0 1 2 3 4 5 6 7 8 9; do printf '%s\n' "2026-01-1$i 10:00	b$i	bright	😀	good	1	3	tapped	none	Sam" >> "$T"; done
printf '%s\n' "2026-01-09 10:00	b9	hugs	😀	good	1	3	tapped	full	Sam" >> "$T"
sumr=$("$BIN/picks-summary.sh" Maya)
grep -q '⚠ POSITION' <<<"$sumr" && grep -q 'bright .*STEADY?(position)' <<<"$sumr" || fail "position-bias warning"

grep -q 'hand-guided ×1 (not counted)' <<<"$sumr" || fail "hand-guided picks must not count"
ok "picks-summary: flags picking-by-position; hand-guided picks don't count"

echo "$pass passed"
