#!/usr/bin/env bash
# Append a captured moment to the interaction ledger — newest-first, atomic, durable.
# Usage: log-moment.sh "free text of the moment"
#        log-moment.sh --asked "the question exactly as asked" --result yes|partial|no ["what they said"]
#        (✓ / ~ / ✗ also accepted)
# The point is to NEVER lose a remembered moment, even rough. Structure it later.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LEDGER="$SKILL_DIR/interaction-ledger.md"
ASKED="" RESULT=""
if [ "${1:-}" = "--asked" ]; then
  ASKED="${2:-}"; shift 2 || true
  [ "${1:-}" = "--result" ] || { echo "log-moment: --asked needs --result ✓|~|✗" >&2; exit 1; }
  RESULT="${2:-}"; shift 2 || true
  # accept words too; an unquoted ~ arrives as $HOME after shell expansion
  case "$RESULT" in
    ✓|yes|y|answered) RESULT="✓" ;;
    '~'|partial|p|"$HOME") RESULT="~" ;;
    ✗|no|n|none) RESULT="✗" ;;
    *) echo "log-moment: --result must be ✓ (yes), ~ (partial) or ✗ (no)" >&2; exit 1 ;;
  esac
  [ -n "$ASKED" ] || { echo "log-moment: empty question" >&2; exit 1; }
fi
TEXT="${*:-}"

[ -z "$TEXT$ASKED" ] && { echo "log-moment: no text given" >&2; exit 1; }
[ -f "$LEDGER" ] || { echo "log-moment: ledger not found (copy interaction-ledger.template.md → interaction-ledger.md)" >&2; exit 1; }

TS="$(date '+%Y-%m-%d %H:%M')"

LEDGER="$LEDGER" TS="$TS" TEXT="$TEXT" ASKED="$ASKED" RESULT="$RESULT" node -e '
const fs = require("fs");
const { LEDGER: p, TS: ts, TEXT: text, ASKED: asked, RESULT: result } = process.env;
let s = fs.readFileSync(p, "utf8");
const entry = asked
  ? `### ${ts} — asked\n` +
    `- **Asked → answered:** "${asked}" → ${result}${text ? ` "${text}"` : ""}\n`
  : `### ${ts} — quick capture\n` +
    `- **Raw note:** ${text}\n` +
    `- *(to structure later: context / their state / what I tried / asked → answered / how they responded / lesson / tags)*\n`;
const marker = "<!-- newest first -->";
// function replacements: the text is inserted literally ("$&", "$$" etc. stay as written)
if (s.includes(marker)) s = s.replace(marker, () => marker + "\n\n" + entry);   // newest on top
else s = s.replace(/\s*$/, () => "\n\n" + entry);                               // fallback: never lose it
const tmp = p + ".tmp-" + process.pid;
fs.writeFileSync(tmp, s);
fs.renameSync(tmp, p);                                                           // atomic: all or nothing
'
echo "logged: $TS"
