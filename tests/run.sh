#!/usr/bin/env bash
# Smoke tests for the capture + learning tools. Run: bash tests/run.sh   (needs node)
set -euo pipefail
SRC="$(cd "$(dirname "$0")/../skill" && pwd)"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
cp -R "$SRC" "$W/skill"; cd "$W/skill"
cp interaction-ledger.template.md interaction-ledger.md
L=interaction-ledger.md; pass=0
ok()   { pass=$((pass+1)); echo "  ok  $*"; }
fail() { echo "  FAIL $*" >&2; exit 1; }

bin/log-moment.sh 'she said "I want $& and $$ \1 now"' >/dev/null
grep -qF 'she said "I want $& and $$ \1 now"' $L || fail "special characters mangled"
ok "log keeps \$&, \$\$ and backslashes exactly as written"

bin/log-moment.sh "second" >/dev/null
a=$(grep -n 'Raw note:\*\* second' $L | cut -d: -f1); b=$(grep -n 'Raw note:\*\* she said' $L | cut -d: -f1)
[ "$a" -lt "$b" ] || fail "not newest-first"
ls $L.tmp-* >/dev/null 2>&1 && fail "temp file left behind"
ok "log is newest-first and leaves no temp files"

bin/log-moment.sh >/dev/null 2>&1 && fail "accepted empty text" || ok "log refuses empty text"
bin/log-moment.sh --asked "Q" --result maybe >/dev/null 2>&1 && fail "accepted bad result" || ok "log refuses an unknown result"

bin/log-moment.sh --asked "How was your day?" --result no >/dev/null
python3 -c "
p='$L'; s=open(p).read(); m='<!-- newest first -->'
open(p,'w').write(s.replace(m, m+'\n\n### Review 2026-10-01\n', 1))"
bin/log-moment.sh --asked "Did Leo come to class today?" --result yes "yes, he sat with me" >/dev/null
bin/log-moment.sh --asked "Did Leo come to class today?" --result ✓ "yes" >/dev/null
bin/log-moment.sh --asked "How was your day?" --result ✗ >/dev/null
bin/log-moment.sh --asked "Was the room cold?" --result ~ "a bit" >/dev/null        # unquoted ~ on purpose
grep -qF '"Was the room cold?" → ~ "a bit"' $L || fail "unquoted ~ was not recorded as partial"
ok "asked → answered lines recorded (yes/✓, no/✗, unquoted ~)"

out=$(bin/question-stats.sh)
grep -q '^5 questions logged · 4 since last review' <<<"$out" || fail "totals: $out"
grep -q 'Did Leo come to class today?  → promote' <<<"$out" || fail "promote suggestion"
grep -q "How was your day?  → move: Doesn't land" <<<"$out" || fail "move suggestion"
grep -qE '^ +0 +1 +0 .*Was the room cold\?$' <<<"$out" || fail "partial count"
! grep -q 'exactly as asked' <<<"$out" || fail "template line counted as a question"
ok "question-stats: honest counts, since-review split, promote/move suggestions"

echo "$pass passed"
