#!/usr/bin/env bash
# Append a captured moment to the interaction ledger — newest-first, atomic, durable.
# Usage:
#   log-moment.sh "free text of the moment"                       quick capture (structure it later)
#   log-moment.sh [--context "car, after school"] [--state "tired, quiet"] \
#                 --asked "the question exactly as asked" --result yes|partial|no [--answer "what they said"] \
#                 [--asked "…" --result … [--answer "…"]] …          one conversation, every question asked
#   log-moment.sh --review "what changed in the profile"           marks a review, so the next one starts here
# Results: yes = ✓ answered · partial = ~ · no = ✗ no answer / distress (✓ ~ ✗ also accepted).
# A bare text right after an --asked item is taken as that item's answer.
# The point is to NEVER lose a remembered moment, even rough. Structure it later.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LEDGER="$SKILL_DIR/interaction-ledger.md"
die() { echo "log-moment: $*" >&2; exit 1; }
need() { [ "$1" -ge 2 ] || die "$2 needs a value"; }   # every option takes one

norm_result() {   # an unquoted ~ arrives as $HOME after shell expansion
  case "$1" in
    ✓|yes|y|answered) echo "✓" ;;
    '~'|partial|p|"${HOME:-/no-home}") echo "~" ;;
    ✗|no|n|none) echo "✗" ;;
    *) return 1 ;;
  esac
}

TEXT="" CONTEXT="" STATE="" REVIEW="" N=0
while [ $# -gt 0 ]; do
  case "$1" in
    --asked)   need $# "$1"; [ -n "$2" ] || die "--asked needs the question"
               N=$((N+1)); export "Q_$N=$2" "R_$N=" "A_$N="; shift 2 ;;
    --result)  need $# "$1"; [ "$N" -gt 0 ] || die "--result must follow --asked"
               r="$(norm_result "${2:-}")" || die "--result must be yes (✓), partial (~) or no (✗)"
               export "R_$N=$r"; shift 2 ;;
    --answer)  need $# "$1"; [ "$N" -gt 0 ] || die "--answer must follow --asked"; export "A_$N=${2:-}"; shift 2 ;;
    --context) need $# "$1"; CONTEXT="${2:-}"; shift 2 ;;
    --state)   need $# "$1"; STATE="${2:-}"; shift 2 ;;
    --review)  need $# "$1"; REVIEW="${2:-}"; [ -n "$REVIEW" ] || die "--review needs a summary"; shift 2 ;;
    --)        shift; TEXT="${TEXT:+$TEXT }$*"; break ;;
    *)         a="A_$N"
               if [ "$N" -gt 0 ] && [ -z "${!a}" ]; then export "A_$N=$1"; else TEXT="${TEXT:+$TEXT }$1"; fi
               shift ;;
  esac
done
i=1; while [ "$i" -le "$N" ]; do r="R_$i"; [ -n "${!r}" ] || die "question $i has no --result"; i=$((i+1)); done
[ -n "$REVIEW" ] && [ "$N" -gt 0 ] && die "log a review on its own"
[ -z "$TEXT$REVIEW" ] && [ "$N" -eq 0 ] && die "no text given"
[ -f "$LEDGER" ] || die "ledger not found (copy interaction-ledger.template.md → interaction-ledger.md)"

TS="$(date '+%Y-%m-%d %H:%M')"

LEDGER="$LEDGER" TS="$TS" TEXT="$TEXT" CONTEXT="$CONTEXT" STATE="$STATE" REVIEW="$REVIEW" N="$N" node -e '
const fs = require("fs"), path = require("path");
const e = process.env, ts = e.TS;
const one = (t) => t.replace(/\r?\n/g, "\n  ");                // keep multi-line text inside its list item
const flat = (t) => t.replace(/\s*\r?\n\s*/g, " ");            // a question stays on one line
const items = [];
for (let i = 1; i <= Number(e.N); i++) items.push({ q: flat(e["Q_" + i]), r: e["R_" + i], a: e["A_" + i] });
const opt = (label, v) => (v ? `- **${label}:** ${one(v)}\n` : "");
let entry;
if (e.REVIEW) {
  entry = `### ${ts} — review\n- **Review:** ${one(e.REVIEW)}\n`;
} else if (items.length) {
  entry = `### ${ts} — asked\n` + opt("Context", e.CONTEXT) + opt("Their state", e.STATE) +
    items.map(({ q, r, a }) => `- **Asked → answered:** "${q}" → ${r}${a ? ` "${one(a)}"` : ""}\n`).join("") +
    opt("Note", e.TEXT);
} else {
  entry = `### ${ts} — quick capture\n` + `- **Raw note:** ${one(e.TEXT)}\n` + opt("Context", e.CONTEXT) + opt("Their state", e.STATE) +
    `- *(to structure later: context / their state / what I tried / asked → answered / how they responded / lesson / tags)*\n`;
}
const real = fs.realpathSync(e.LEDGER);                          // write through a symlink, never replace it
let s = fs.readFileSync(real, "utf8");
const marker = "<!-- newest first -->";
// function replacements: the text is inserted literally ("$&", "$$" etc. stay as written)
if (s.includes(marker)) s = s.replace(marker, () => marker + "\n\n" + entry);   // newest on top
else s = s.replace(/\s*$/, () => "\n\n" + entry);                               // fallback: never lose it
const mode = fs.statSync(real).mode & 0o777;
const tmp = path.join(path.dirname(real), "." + path.basename(real) + ".tmp-" + process.pid);
fs.writeFileSync(tmp, s, { mode: 0o600 });
fs.chmodSync(tmp, mode);                                                         // keep the ledger'"'"'s own permissions
fs.renameSync(tmp, real);                                                        // atomic: all or nothing
'
echo "logged: $TS"
