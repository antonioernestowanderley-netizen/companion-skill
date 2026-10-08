# Shared helpers — sourced by the other scripts.
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA="${COMPANION_DATA:-$SKILL_DIR/data}"
die() { echo "$(basename "$0"): $*" >&2; exit 1; }
check_name() {
  case "$1" in
    ""|*/*|*" "*|.*|*-by-*) die "bad name '$1' (no spaces, slashes, leading dot, or '-by-')" ;;
  esac
}

# ── picture cards ────────────────────────────────────────────────
PICKS_DIR="$DATA/picks"
deck_file() { if [ -f "$DATA/cards.md" ]; then echo "$DATA/cards.md"; else echo "$SKILL_DIR/templates/cards.md"; fi; }

# deck_tsv <lang>  →  id \t section \t question \t "opt | opt | …"   (falls back to English)
deck_tsv() {
  awk -v L="$1" '
    function pick(a,   r) { r = (L in a) ? a[L] : a["en"]; return r }
    function flush(   o) {
      if (id != "") {
        o = pick(opt); if (o == "faces") o = pick(faces)
        print id "\t" sec "\t" pick(ask) "\t" o
      }
      id = ""; sec = ""; split("", ask); split("", opt)
    }
    /^### / { flush(); id = substr($0, 5); sub(/[ \t]+$/, "", id); next }
    /^- [a-z-]+:/ {
      k = substr($0, 3); sub(/:.*/, "", k)
      v = $0; sub(/^- [a-z-]+:[ \t]*/, "", v); sub(/[ \t]+$/, "", v)
      if (k ~ /^faces-/)        faces[substr(k, 7)] = v
      else if (id == "")        next
      else if (k == "section")  sec = v
      else if (k == "options")  opt["en"] = v
      else if (k ~ /^options-/) opt[substr(k, 9)] = v
      else                      ask[k] = v
    }
    END { flush() }' "$(deck_file)"
}

# other_of <subject>  →  the other person's name, from the portrait filenames
other_of() {
  local f n
  for f in "$DATA/portraits/$1-by-"*.md; do
    n="${f##*/$1-by-}"; n="${n%.md}"
    [ -e "$f" ] && [ "$n" != "$1" ] && { echo "$n"; return; }
  done
  echo "them"
}
