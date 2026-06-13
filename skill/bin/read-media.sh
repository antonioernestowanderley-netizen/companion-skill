#!/usr/bin/env bash
# Turn an inbound voice note or conversation screenshot into TEXT — fully local, no cloud.
#   image  -> macOS Vision OCR (build ocr-vision from ocr-vision.swift first; falls back to tesseract)
#   audio  -> local whisper transcription (auto language)
# Usage: read-media.sh <path-to-image-or-audio>
# Prints the extracted text to stdout. Privacy: nothing leaves this machine.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
F="${1:-}"
[ -f "$F" ] || { echo "read-media: file not found: $F" >&2; exit 1; }

ext="$(printf '%s' "${F##*.}" | tr 'A-Z' 'a-z')"

ocr_image() {
  # Prefer macOS Vision (local, multilingual, reads png/jpg/heic). Build once:
  #   swiftc -O bin/ocr-vision.swift -o bin/ocr-vision
  if [ -x "$HERE/ocr-vision" ]; then
    "$HERE/ocr-vision" "$1"
  elif command -v tesseract >/dev/null 2>&1; then
    tesseract "$1" stdout 2>/dev/null
  else
    echo "read-media: no OCR engine (build ocr-vision or install tesseract)" >&2; exit 1
  fi
}

transcribe_audio() {
  local aud="$1" tmp; tmp="$(mktemp -d)"
  # multilingual base model, auto-detect language; ffmpeg decodes WhatsApp .ogg/opus
  whisper "$aud" --model base --output_format txt --output_dir "$tmp" --fp16 False --verbose False >/dev/null 2>&1 || true
  cat "$tmp"/*.txt 2>/dev/null
  rm -rf "$tmp"
}

case "$ext" in
  png|jpg|jpeg|webp|gif|bmp|tif|tiff|heic) ocr_image "$F" ;;
  ogg|oga|opus|m4a|mp3|wav|aac|flac|mp4)   transcribe_audio "$F" ;;
  *) echo "read-media: unsupported type .$ext" >&2; exit 1 ;;
esac
