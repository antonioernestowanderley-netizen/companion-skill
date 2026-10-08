#!/usr/bin/env bash
# Create a pair's private data folder from the templates.
# Usage: init.sh <A> <B>     A = you (the one setting it up), B = the other person.
# Creates data/{pair,ledger,shared}.md and four portraits: A-by-A, A-by-B, B-by-B, B-by-A.
# Never overwrites. Migrates a v1 profile.md / interaction-ledger.md if found.
set -euo pipefail
. "$(dirname "$0")/_lib.sh"

A="${1:-}"; B="${2:-}"
[ -n "$A" ] && [ -n "$B" ] || die "usage: init.sh <you> <them>"
check_name "$A"; check_name "$B"
[ "$A" != "$B" ] || die "the two names must differ"
[ -e "$DATA/pair.md" ] && die "already initialised at $DATA — not overwriting"

umask 077
mkdir -p "$DATA/portraits"
T="$SKILL_DIR/templates"

# render <template> <out> KEY=VALUE…  (literal {{KEY}} replacement, no regex surprises)
render() {
  local tpl="$1" out="$2"; shift 2
  [ -e "$out" ] && return 0
  env "$@" awk '
    { line = $0
      for (k in ENVIRON) {
        tag = "{{" k "}}"
        while ((i = index(line, tag)) > 0)
          line = substr(line, 1, i - 1) ENVIRON[k] substr(line, i + length(tag))
      }
      print line }' "$tpl" > "$out"
}

render "$T/pair.template.md"   "$DATA/pair.md"   A="$A" B="$B"
render "$T/shared.template.md" "$DATA/shared.md" A="$A" B="$B"

portrait() {  # subject author
  local s="$1" a="$2"
  if [ "$s" = "$a" ]; then
    render "$T/portrait.template.md" "$DATA/portraits/$s-by-$a.md" \
      SUBJECT="$s" AUTHOR="$a" KIND=self VISIBLE=author-only \
      TITLE="in my own words" \
      INTRO="Written by $s about themselves — typed, dictated, chosen from options, drawn, or with help. This is the authority on what it is like to be $s."
  else
    render "$T/portrait.template.md" "$DATA/portraits/$s-by-$a.md" \
      SUBJECT="$s" AUTHOR="$a" KIND=seen VISIBLE=author-only \
      TITLE="as seen by $a" \
      INTRO="Written by $a: what $a notices from the outside. A witness view, not the truth about $s."
  fi
}
portrait "$A" "$A"; portrait "$A" "$B"; portrait "$B" "$B"; portrait "$B" "$A"

# v1 migration: the old profile was written by the owner (A) about the other person (B).
if [ -f "$SKILL_DIR/profile.md" ]; then
  { printf -- '---\nsubject: %s\nauthor: %s\nkind: seen\nvisible-to: author-only\nupdated:\n---\n\n' "$B" "$A"
    cat "$SKILL_DIR/profile.md"; } > "$DATA/portraits/$B-by-$A.md"
  echo "migrated: profile.md → portraits/$B-by-$A.md (original left in place)"
fi
if [ -f "$SKILL_DIR/interaction-ledger.md" ]; then
  cp "$SKILL_DIR/interaction-ledger.md" "$DATA/ledger.md"
  echo "migrated: interaction-ledger.md → ledger.md (original left in place)"
else
  cp "$T/ledger.template.md" "$DATA/ledger.md"
fi

cat <<MSG
ready: $DATA
next:
  1. fill pair.md (members, languages, emergency plan)
  2. each of you fills your own portraits — self first, then the other
  3. when you're ready to share a portrait, set  visible-to: both  in its header
MSG
