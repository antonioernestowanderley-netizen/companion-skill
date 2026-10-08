// Local OCR using the macOS Vision framework — private, multilingual, no cloud.
// Build once:  swiftc -O ocr-vision.swift -o ocr-vision
// Use:         ./ocr-vision <image-path>   (png/jpg/heic/…)
import Foundation
import Vision
import AppKit

let a = CommandLine.arguments
guard a.count > 1, let img = NSImage(contentsOfFile: a[1]),
      let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
  FileHandle.standardError.write("ocr: cannot load image\n".data(using: .utf8)!); exit(1)
}
let req = VNRecognizeTextRequest { req, _ in
  for o in (req.results as? [VNRecognizedTextObservation] ?? []) {
    if let t = o.topCandidates(1).first { print(t.string) }
  }
}
req.recognitionLevel = .accurate
// Add/adjust languages to match the people in your life:
req.recognitionLanguages = ["pt-BR", "en-US"]
req.usesLanguageCorrection = true
try? VNImageRequestHandler(cgImage: cg, options: [:]).perform([req])
