#!/usr/bin/env bash
# Tests for the capture + learning tools and the skill's wiring. Run: bash tests/run.sh   (needs node, python3)
set -euo pipefail
SRC="$(cd "$(dirname "$0")/../skill" && pwd)"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
cp -R "$SRC" "$W/skill"; cd "$W/skill"
cp interaction-ledger.template.md interaction-ledger.md
L=interaction-ledger.md; pass=0
ok()   { pass=$((pass+1)); echo "  ok  $*"; }
fail() { echo "  FAIL $*" >&2; exit 1; }
mode() { node -e 'console.log((require("fs").statSync(process.argv[1]).mode & 0o777).toString(8))' "$1"; }
no_temp() { ! ls -a | grep -q '\.tmp-'; }

# ── the skill's wiring ─────────────────────────────────────────────
python3 - SKILL.md <<'PY' || fail "SKILL.md frontmatter"
import sys, re
s = open(sys.argv[1]).read()
m = re.match(r'^---\n(.*?)\n---\n', s, re.S); assert m, "no frontmatter"
keys = {}
for line in m.group(1).splitlines():
    assert not line.startswith(' '), "nested key (OpenClaw reads user-invocable at top level): " + line
    k, _, v = line.partition(':'); keys[k] = v.strip()
assert keys.get('name') == 'companion'
assert 0 < len(keys['description']) <= 1024, "description must be 1–1024 chars"
assert ': ' not in keys['description'], "': ' inside a plain YAML scalar breaks parsing"
assert keys.get('user-invocable') == 'true'
PY
for f in translation-guide.md bibliography.md common-core.md profile.template.md interaction-ledger.template.md \
         bin/log-moment.sh bin/question-stats.sh bin/read-media.sh; do
  [ -e "$f" ] || fail "SKILL.md names $f but it doesn't exist"
  grep -q "${f##*/}" SKILL.md || fail "$f is not referenced from SKILL.md"
done
ok "SKILL.md: valid top-level frontmatter; every file it names exists"

# ── capture ────────────────────────────────────────────────────────
bin/log-moment.sh 'she said "I want $& and $$ \1 now"' >/dev/null
grep -qF 'she said "I want $& and $$ \1 now"' $L || fail "special characters mangled"
ok "log keeps \$&, \$\$ and backslashes exactly as written"

bin/log-moment.sh "second" >/dev/null
a=$(grep -n 'Raw note:\*\* second' $L | cut -d: -f1); b=$(grep -n 'Raw note:\*\* she said' $L | cut -d: -f1)
[ "$a" -lt "$b" ] && no_temp || fail "not newest-first, or a temp file was left behind"
ok "log is newest-first and leaves no temp files"

bin/log-moment.sh >/dev/null 2>&1 && fail "accepted empty text"
bin/log-moment.sh 'plain capture with no questions' >/dev/null   # regression: N=0 must not run the R_ check (bash 3.2 seq 1 0 emits "1 0")
grep -qF 'plain capture with no questions' $L || fail "N=0 capture rejected or lost"
bin/log-moment.sh --asked "Q" --result maybe >/dev/null 2>&1 && fail "accepted an unknown result"
bin/log-moment.sh --asked "Q" >/dev/null 2>&1 && fail "accepted a question with no result"
bin/log-moment.sh --result yes >/dev/null 2>&1 && fail "accepted --result without --asked"
msg=$(bin/log-moment.sh "note" --context 2>&1) && fail "accepted an option with no value"; grep -q "needs a value" <<<"$msg" || fail "no message for a missing value"
ok "log refuses empty text, unknown results, missing results, stray --result, options with no value; and a plain N=0 capture still lands"

chmod 600 $L
mv $L ../real-ledger.md && ln -s ../real-ledger.md $L
bin/log-moment.sh "through the link" >/dev/null
[ -L $L ] && grep -q 'through the link' ../real-ledger.md && [ "$(mode ../real-ledger.md)" = 600 ] && no_temp \
  || fail "symlink replaced or permissions changed"
rm $L && mv ../real-ledger.md $L
ok "log writes through a symlink and keeps the ledger's permissions (600 stays 600)"

# ── the learning loop ──────────────────────────────────────────────
bin/log-moment.sh --asked "How was your day?" --result no >/dev/null
bin/log-moment.sh --review "promoted the day-rating question" >/dev/null
grep -q '^### .* — review$' $L || fail "review marker"
bin/log-moment.sh --context "car, after school" --state "tired, quiet" \
  --asked "Did Leo come to class today?" --result yes --answer "yes, he sat with me" \
  --asked "Was the room cold?" --result ~ "a bit" \
  --asked 'Did you say "bye" to Ms Rivera?' --result partial >/dev/null          # unquoted ~ and a positional answer on purpose
entry=$(awk '/— asked$/{p=1} p{print} /Ms Rivera/{exit}' $L)
for want in '**Context:** car, after school' '**Their state:** tired, quiet' \
            '"Did Leo come to class today?" → ✓ "yes, he sat with me"' '"Was the room cold?" → ~ "a bit"'; do
  grep -qF "$want" <<<"$entry" || fail "multi-question entry missing: $want"
done
[ "$(grep -c '— asked$' <<<"$entry")" = 1 ] || fail "one conversation should be one entry"
ok "one conversation = one entry: context, their state, every question, unquoted ~, positional answer"

bin/log-moment.sh --asked "did leo come to class today" --result ✓ >/dev/null       # same question, different case/punctuation
bin/log-moment.sh --asked "How was your day?" --result ✗ >/dev/null
bin/log-moment.sh --asked "Was the room cold?" --result yes >/dev/null
bin/log-moment.sh --asked "Was the room cold?" --result no >/dev/null
out=$(bin/question-stats.sh)
grep -q '^8 questions logged · 7 since last review (### .* — review)' <<<"$out" || fail "totals: $out"
grep -q 'Did Leo come to class today?  → promote' <<<"$out" || fail "promote (and case/punctuation grouping): $out"
grep -q "How was your day?  → move: Doesn't land" <<<"$out" || fail "move"
grep -q 'Was the room cold?  → mixed: compare context and state' <<<"$out" || fail "mixed"
grep -qF 'Did you say "bye" to Ms Rivera?' <<<"$out" || fail "a question containing quotes was cut short"
! grep -q 'exactly as asked' <<<"$out" || fail "template line counted as a question"
ok "question-stats: honest counts, since-review split, promote / move / mixed, robust to quotes and case"

# ── voice notes: never lose a moment silently ──────────────────────
mkdir -p "$W/fakebin"; printf 'x' > "$W/note.ogg"
bin/read-media.sh "$W/missing.ogg" >/dev/null 2>&1 && fail "missing file accepted"
bin/read-media.sh "$W/note.xyz" >/dev/null 2>&1 && fail "unsupported type accepted"
printf '#!/bin/sh\nexit 1\n' > "$W/fakebin/whisper"; chmod +x "$W/fakebin/whisper"
set +e; msg=$(PATH="$W/fakebin:$PATH" bin/read-media.sh "$W/note.ogg" 2>&1 >/dev/null); rc=$?; set -e
[ "$rc" = 2 ] && grep -q "type the moment instead" <<<"$msg" || fail "failed transcription should say so and exit 2 (got $rc: $msg)"
cat > "$W/fakebin/whisper" <<'SH'
#!/bin/sh
while [ $# -gt 0 ]; do [ "$1" = --output_dir ] && d="$2"; shift; done
echo "ela disse que o Leo faltou" > "$d/note.txt"
SH
[ "$(PATH="$W/fakebin:$PATH" bin/read-media.sh "$W/note.ogg")" = "ela disse que o Leo faltou" ] || fail "transcript not printed"
ok "read-media: says so and exits non-zero when nothing can be read; prints the transcript when it can"

echo "$pass passed"
