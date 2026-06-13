#!/usr/bin/env bash
# Append a captured moment to the interaction ledger — newest-first, atomic, durable.
# Usage: log-moment.sh "free text of the moment"
# The point is to NEVER lose a remembered moment, even rough. Structure it later.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LEDGER="$SKILL_DIR/interaction-ledger.md"
TEXT="${*:-}"

[ -z "$TEXT" ] && { echo "log-moment: no text given" >&2; exit 1; }
[ -f "$LEDGER" ] || { echo "log-moment: ledger not found (copy interaction-ledger.template.md → interaction-ledger.md)" >&2; exit 1; }

TS="$(date '+%Y-%m-%d %H:%M')"

LEDGER="$LEDGER" TS="$TS" TEXT="$TEXT" node -e '
const fs = require("fs");
const p = process.env.LEDGER, ts = process.env.TS, text = process.env.TEXT;
let s = fs.readFileSync(p, "utf8");
const entry =
  `### ${ts} — quick capture\n` +
  `- **Raw note:** ${text}\n` +
  `- *(to structure later: context / their state / what I tried / how they responded / lesson / tags)*\n`;
const marker = "<!-- newest first -->";
if (s.includes(marker)) s = s.replace(marker, marker + "\n\n" + entry);   // newest on top
else s = s.replace(/\s*$/, "") + "\n\n" + entry;                          // fallback: never lose it
fs.writeFileSync(p, s);
'
echo "logged: $TS"
