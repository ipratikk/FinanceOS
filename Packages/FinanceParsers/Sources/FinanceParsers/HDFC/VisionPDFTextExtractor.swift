import Foundation

#if canImport(PDFKit)
import PDFKit
#endif

/// Extracts row-ordered text lines from a PDF page.
///
/// Implementations may use PDFKit character bounds, OCR, or any other
/// strategy. The contract is: return lines in top-down reading order,
/// with horizontally-adjacent tokens joined into a single line per row.
public protocol PDFTextExtractor: Sendable {
    #if canImport(PDFKit)
    func extractLines(from page: PDFPage) -> [String]
    #endif
}

#if canImport(Vision) && canImport(AppKit) && canImport(PDFKit)
import AppKit
import Vision

/// Vision-based OCR extractor. Renders the page to a high-resolution
/// raster, runs `VNRecognizeTextRequest` in accurate mode, then groups
/// recognized observations into rows by normalized Y coordinate.
public struct VisionPDFTextExtractor: PDFTextExtractor {
    private let renderScale: CGFloat
    private let yTolerance: CGFloat

    public init(renderScale: CGFloat = 3.0, yTolerance: CGFloat = 0.015) {
        self.renderScale = renderScale
        self.yTolerance = yTolerance
    }

    public func extractLines(from page: PDFPage) -> [String] {
        guard let cgImage = renderPage(page) else {
            return []
        }
        let observations = recognizeText(in: cgImage)
        return groupIntoRows(observations)
    }

    private func renderPage(_ page: PDFPage) -> CGImage? {
        let pageRect = page.bounds(for: .mediaBox)
        let width = Int(pageRect.width * renderScale)
        let height = Int(pageRect.height * renderScale)
        guard width > 0, height > 0 else { return nil }

        // CGBitmapContext is thread-safe and does not require an AppKit run
        // loop. NSImage.lockFocus only works reliably on the main thread,
        // which fails silently inside an async parser running on a Swift
        // concurrency worker thread.
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { return nil }

        ctx.setFillColor(CGColor.white)
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        ctx.scaleBy(x: renderScale, y: renderScale)
        page.draw(with: .mediaBox, to: ctx)

        return ctx.makeImage()
    }

    private func recognizeText(in cgImage: CGImage) -> [Observation] {
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false

        do {
            try handler.perform([request])
        } catch {
            return []
        }

        guard let results = request.results else {
            return []
        }
        var out: [Observation] = []
        out.reserveCapacity(results.count)
        for result in results {
            guard let top = result.topCandidates(1).first else { continue }
            let box = result.boundingBox
            out.append(Observation(text: top.string, y: box.origin.y, x: box.origin.x))
        }
        return out
    }

    private func groupIntoRows(_ observations: [Observation]) -> [String] {
        var buckets: [(y: CGFloat, items: [Observation])] = []
        for obs in observations {
            if let idx = buckets.firstIndex(where: { abs($0.y - obs.y) <= yTolerance }) {
                buckets[idx].items.append(obs)
            } else {
                buckets.append((y: obs.y, items: [obs]))
            }
        }
        // Vision normalized Y: 1.0 = top of page, 0.0 = bottom.
        buckets.sort { $0.y > $1.y }

        var lines: [String] = []
        lines.reserveCapacity(buckets.count)
        for bucket in buckets {
            // Sort observations left-to-right within row, preserving reading order
            let sorted = bucket.items.sorted { $0.x < $1.x }
            let joined = sorted.map(\.text).joined(separator: " ")
            let trimmed = joined.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                lines.append(trimmed)
            }
        }
        return lines
    }

    private struct Observation {
        let text: String
        let y: CGFloat
        let x: CGFloat
    }
}
#endif
