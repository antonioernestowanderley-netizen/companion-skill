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
sed -i 's/^- Processing time needed:$/- Processing time needed: lots — count to ten/' "$P/Maya-by-Maya.md"
sed -i 's/^- Processing time needed:$/- Processing time needed: she answers fast/' "$P/Maya-by-Sam.md"
out=$("$BIN/side-by-side.sh" Maya Maya)
grep -q 'count to ten' <<<"$out" && ! grep -q 'answers fast' <<<"$out" || fail "visibility: private witness view leaked"
ok "side-by-side hides portraits not shared with the viewer"

sed -i 's/^visible-to: author-only/visible-to: both/' "$P/Maya-by-Sam.md"
out=$("$BIN/side-by-side.sh" Maya Maya)
grep -q 'answers fast' <<<"$out" && grep -q '### seen by Sam' <<<"$out" || fail "shared witness view missing"
awk '/### self/{s=NR} /### seen by Sam/{w=NR} END{exit !(s<w)}' <<<"$out" || fail "self should come first"
! grep -qE 'Getting things across|idioms OK\?' <<<"$out" || fail "blank stubs shown"
ok "side-by-side shows shared views, self first, blanks hidden"

echo "$pass passed"
