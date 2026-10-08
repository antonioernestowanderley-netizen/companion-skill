#!/usr/bin/env bash
# Line up every portrait OF one person, section by section, for the Mirror.
# Usage: side-by-side.sh <subject> <viewer>
# Shows only portraits the viewer may see (visible-to: both, or the viewer wrote it).
# Hides untouched template lines so only what was actually written appears.
set -euo pipefail
. "$(dirname "$0")/_lib.sh"

S="${1:-}"; V="${2:-}"
[ -n "$S" ] && [ -n "$V" ] || die "usage: side-by-side.sh <subject> <viewer>"
check_name "$S"; check_name "$V"
shopt -s nullglob
files=("$DATA/portraits/$S-by-"*.md)
[ ${#files[@]} -gt 0 ] || die "no portraits of '$S' in $DATA/portraits"

awk -v viewer="$V" -v subject="$S" '
  FILENAME == ARGV[1] { stub[$0] = 1; next }                # template lines = unfilled stubs
  function val(s) { sub(/^[^:]*:[ \t]*/, "", s); sub(/[ \t]*#.*$/, "", s); return s }
  FNR == 1 { f++; fm = 0; sec = "" }
  FNR == 1 && /^---[ \t]*$/ { fm = 1; next }
  fm && /^---[ \t]*$/ { fm = 0; next }
  fm { if ($0 ~ /^author:/) au[f] = val($0)
       else if ($0 ~ /^kind:/) kd[f] = val($0)
       else if ($0 ~ /^visible-to:/) vs[f] = val($0)
       next }
  /^## / { sec = substr($0, 4); sub(/[ \t]*\*\(.*\)\*[ \t]*$/, "", sec)
           if (!(sec in seen)) { seen[sec] = 1; order[++n] = sec }; next }
  sec == "" || /^[ \t]*$/ || ($0 in stub) { next }
  { body[f, sec] = body[f, sec] $0 "\n"; any[sec] = 1 }
  END {
    for (j = 1; j <= f; j++) ok[j] = (vs[j] == "both" || au[j] == viewer)
    printf "# Mirror input — %s, as seen by viewer %s\n", subject, viewer
    for (i = 1; i <= n; i++) {
      s = order[i]; if (!(s in any)) continue
      printf "\n## %s\n", s
      for (pass = 1; pass <= 2; pass++)
        for (j = 1; j <= f; j++) {
          if (!ok[j] || (pass == 1) != (au[j] == subject)) continue
          printf "### %s\n", (au[j] == subject ? "self (" subject ")" : "seen by " au[j])
          printf "%s", ((j, s) in body ? body[j, s] : "_(blank)_\n")
        }
    }
  }
' "$SKILL_DIR/templates/portrait.template.md" "${files[@]}"
