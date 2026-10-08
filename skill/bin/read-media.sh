#!/usr/bin/env bash
# Turn a voice note or chat screenshot into TEXT, on this machine.
#   image -> macOS Vision OCR (build ocr-vision first; falls back to tesseract)
#            marks chat bubbles: ◀ left (usually the other person) · ▶ right (usually you)
#   audio -> local whisper (WHISPER_MODEL, default "small"; "base" is weak for Portuguese)
# Usage: read-media.sh <file>
# Exits non-zero and says so if nothing could be read, so a moment is never lost silently.
set -euo pipefail
. "$(dirname "$0")/_lib.sh"
HERE="$SKILL_DIR/bin"

F="${1:-}"
[ -f "$F" ] || die "file not found: $F"
ext="$(printf '%s' "${F##*.}" | tr 'A-Z' 'a-z')"

ocr_image() {
  if [ -x "$HERE/ocr-vision" ]; then "$HERE/ocr-vision" "$1"
  elif command -v tesseract >/dev/null 2>&1; then tesseract "$1" stdout 2>/dev/null
  else die "no OCR engine (build bin/ocr-vision or install tesseract)"; fi
}

transcribe_audio() {
  command -v whisper >/dev/null 2>&1 || die "whisper not installed (pip install openai-whisper; needs ffmpeg)"
  local tmp; tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  whisper "$1" --model "${WHISPER_MODEL:-small}" --output_format txt --output_dir "$tmp" \
          --fp16 False --verbose False >"$tmp/log" 2>&1 \
    || { tail -n 5 "$tmp/log" >&2; die "whisper failed on $1"; }
  cat "$tmp"/*.txt
}

case "$ext" in
  png|jpg|jpeg|webp|gif|bmp|tif|tiff|heic) out="$(ocr_image "$F")" ;;
  ogg|oga|opus|m4a|mp3|wav|aac|flac|mp4)   out="$(transcribe_audio "$F")" ;;
  *) die "unsupported type .$ext" ;;
esac

[ -n "$(printf '%s' "$out" | tr -d '[:space:]')" ] || die "read nothing from $F — keep the file and type the moment instead"
printf '%s\n' "$out"
