// Local OCR using the macOS Vision framework — on-device, multilingual.
// Build once:  swiftc -O ocr-vision.swift -o ocr-vision
// Use:         ./ocr-vision <image>          (png/jpg/heic/…)
// Env:         OCR_LANGS=pt-BR,en-US         recognition languages, in priority order
//              OCR_SIDES=0                   turn off chat-bubble side markers
// In chat screenshots, lines hugging the left edge get "◀ " (usually the other person)
// and lines hugging the right edge get "▶ " (usually you), so who-said-what survives.
import Foundation
import Vision
import AppKit

func fail(_ msg: String, _ code: Int32) -> Never {
  FileHandle.standardError.write("ocr: \(msg)\n".data(using: .utf8)!); exit(code)
}

let args = CommandLine.arguments
guard args.count > 1, let img = NSImage(contentsOfFile: args[1]),
      let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
  fail("cannot load image", 1)
}
let env = ProcessInfo.processInfo.environment
let langs = (env["OCR_LANGS"] ?? "pt-BR,en-US")
  .split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
let sides = env["OCR_SIDES"] != "0"

let req = VNRecognizeTextRequest()
req.recognitionLevel = .accurate
req.recognitionLanguages = langs
req.usesLanguageCorrection = true
do { try VNImageRequestHandler(cgImage: cg, options: [:]).perform([req]) }
catch { fail(error.localizedDescription, 1) }

// Vision's boundingBox is normalised, origin bottom-left; sort top-to-bottom.
var lines: [(y: CGFloat, text: String)] = []
for o in req.results ?? [] {
  guard let t = o.topCandidates(1).first?.string else { continue }
  let b = o.boundingBox
  var tag = ""
  if sides {
    if b.minX < 0.15 && b.maxX < 0.85 { tag = "◀ " }
    else if b.maxX > 0.85 && b.minX > 0.15 { tag = "▶ " }
  }
  lines.append((b.midY, tag + t))
}
if lines.isEmpty { fail("no text found", 2) }
if sides { print("# ◀ left bubble (usually the other person) · ▶ right bubble (usually you)") }
for l in lines.sorted(by: { $0.y > $1.y }) { print(l.text) }
