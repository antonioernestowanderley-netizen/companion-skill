#!/usr/bin/env bash
# Summarise picture-session picks for one person, grouped by portrait section.
# STEADY  = 3+ own-choice answers, on 2+ days, one picture chosen ≥75% of the time → may go into the self-portrait
# EMERGING = not enough yet · MIXED = enough answers, no clear choice (also an answer: "it depends")
# Flags picking-by-position and sessions that were always run by the same person.
# Usage: picks-summary.sh <subject>
set -euo pipefail
. "$(dirname "$0")/_lib.sh"

S="${1:-}"; [ -n "$S" ] || die "usage: picks-summary.sh <subject>"
check_name "$S"
PICKS="$PICKS_DIR/$S.tsv"
[ -f "$PICKS" ] || die "no picks recorded for $S yet"

deck_tsv en | awk -F'\t' -v name="$S" -v other="$(other_of "$S")" '
  FNR == NR { sec[$1] = $2; q[$1] = $3; while ((x = index(q[$1], "{{OTHER}}")) > 0) q[$1] = substr(q[$1], 1, x-1) other substr(q[$1], x+9); order[++nc] = $1; next }   # deck (English, for structure)
  FNR == 1 { next }                                                 # picks header
  {
    card = $3; k = $4
    if (card == "feel-now") next                                    # warm-up gate, not portrait data
    sessions[$2] = 1; runner[$10 == "" ? "?" : $10]++
    if (k == "—") { skip[card]++; seen[card] = 1; next }
    if ($9 == "full") { guided[card]++; seen[card] = 1; next }      # hand-over-hand: not their choice
    seen[card] = 1; ans[card]++; cnt[card, k]++; lab[card, k] = $5
    if (!((card, k) in firstk)) { firstk[card, k] = 1; keys[card] = keys[card] SUBSEP k }
    d = substr($1, 1, 10); if (!((card, d) in day)) { day[card, d] = 1; days[card]++ }
    if ($6 ~ /^[0-9]+$/ && $7 + 0 >= 2) { npos++; if ($6 == 1) p1++; if ($6 == $7) plast++ }
    total++
  }
  END {
    ns = 0; for (s in sessions) ns++
    printf "# Picture picks — %s  (%d own-choice answers · %d session%s · run by:", name, total, ns, (ns == 1 ? "" : "s")
    nr = 0; for (r in runner) { printf " %s ×%d", r, runner[r]; nr++ }; print ")"
    if (npos >= 6 && (p1 / npos >= 0.7 || plast / npos >= 0.7))
      printf "\n⚠ POSITION: %d%% of picks were the %s picture shown. They may be choosing by place, not meaning. Treat nothing below as steady yet; keep sessions short and concrete, use photos.\n", int(100 * (p1 >= plast ? p1 : plast) / npos), (p1 >= plast ? "first" : "last")
    if (nr == 1 && total >= 6)
      print "\nℹ All sessions were run by one person. Have someone else run one sometimes; the person showing the cards can shape the answers without meaning to."
    bias = (npos >= 6 && (p1 / npos >= 0.7 || plast / npos >= 0.7))
    for (i = 1; i <= nc; i++) {
      c = order[i]; if (!(c in seen)) continue
      s = sec[c]; if (!(s in printed)) { printf "\n## %s\n", s; printed[s] = 1 }
      if (!(c in ans)) { printf "- %s — \"%s\" → no own-choice answer yet", c, q[c] }
      else {
        top = ""; tn = 0; m = split(keys[c], ks, SUBSEP); detail = ""
        for (j = 2; j <= m; j++) { k = ks[j]; detail = detail (detail ? " · " : "") k " " lab[c, k] " " cnt[c, k]; if (cnt[c, k] > tn) { tn = cnt[c, k]; top = k } }
        status = (ans[c] >= 3 && days[c] >= 2 && tn / ans[c] >= 0.75) ? (bias ? "STEADY?(position)" : "STEADY") : (ans[c] >= 3 && days[c] >= 2 ? "MIXED" : "EMERGING")
        printf "- %s — \"%s\" → %s %s %d/%d · %d day%s — %s  [picks %s %d/%d]", c, q[c], top, lab[c, top], tn, ans[c], days[c], (days[c] > 1 ? "s" : ""), status, c, tn, ans[c]
        if (m > 2) printf "\n    (%s)", detail
      }
      if (skip[c]) printf " · skipped ×%d", skip[c]
      if (guided[c]) printf " · hand-guided ×%d (not counted)", guided[c]
      print ""
    }
  }' - "$PICKS"
