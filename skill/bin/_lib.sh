# Shared helpers — sourced by the other scripts.
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA="${COMPANION_DATA:-$SKILL_DIR/data}"
die() { echo "$(basename "$0"): $*" >&2; exit 1; }
check_name() {
  case "$1" in
    ""|*/*|*" "*|.*|*-by-*) die "bad name '$1' (no spaces, slashes, leading dot, or '-by-')" ;;
  esac
}
