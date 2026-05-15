import Foundation

#if canImport(PDFKit)
import PDFKit

public struct HDFCPDFParser: StatementParser {
    public let supportedFormat: StatementFileFormat = .pdf
    private let password: String?
    private let visionExtractor: PDFTextExtractor?

    public init(password: String? = nil) {
        self.password = password
        #if canImport(Vision) && canImport(AppKit)
        visionExtractor = VisionPDFTextExtractor()
        print("HDFCPDFParser: Vision available, created VisionPDFTextExtractor")
        #else
        visionExtractor = nil
        print("HDFCPDFParser: Vision NOT available, will use PDFKit fallback")
        #endif
    }

    public func parseStatement(from fileURL: URL) async throws -> ParsedStatement {
        guard let doc = PDFDocument(url: fileURL) else {
            throw TransactionImportError.malformedFile("Cannot open PDF")
        }

        if doc.isLocked {
            guard let pwd = password else {
                let filename = fileURL.lastPathComponent
                throw TransactionImportError.passwordProtected(filename)
            }

            let trimmedPwd = pwd.trimmingCharacters(in: .whitespaces)
            _ = doc.unlock(withPassword: trimmedPwd)
            if doc.isLocked {
                _ = doc.unlock(withPassword: pwd)
            }

            if doc.isLocked {
                let filename = fileURL.lastPathComponent
                throw TransactionImportError.passwordProtected(filename)
            }
        }

        var lines: [String] = []
        for i in 0 ..< doc.pageCount {
            guard let page = doc.page(at: i) else { continue }
            lines.append(contentsOf: extractLines(from: page))
        }

        guard let headerIdx = lines.firstIndex(where: { line in
            let lower = line.lowercased()
            let hasDate = lower.contains("date")
            let hasNarration = lower.contains("narration")
            return hasDate && hasNarration
        }) else {
            throw TransactionImportError.malformedFile("No transaction table found in PDF")
        }

        let metadata = HDFCMetadataExtractor().extract(from: collectPDFKitLines(from: doc))
        let transactions = try parseHDFCTransactions(Array(lines[headerIdx...]))
        let (periodStart, periodEnd) = extractPeriod(from: transactions)

        var totalDebit: Int64 = 0
        var totalCredit: Int64 = 0
        for txn in transactions {
            if txn.amountMinorUnits < 0 {
                totalDebit -= txn.amountMinorUnits
            } else {
                totalCredit += txn.amountMinorUnits
            }
        }

        return ParsedStatement(
            bankName: "HDFC",
            accountName: metadata.accountNumber ?? "Unknown",
            statementPeriodStart: periodStart,
            statementPeriodEnd: periodEnd,
            currency: "INR",
            totalDebit: totalDebit,
            totalCredit: totalCredit,
            transactions: transactions,
            metadata: metadata
        )
    }

    /// Returns the concatenated newline-split text of all pages using
    /// PDFKit's native text extraction. Unlike Vision OCR, this preserves
    /// header layout reliably for metadata extraction.
    private func collectPDFKitLines(from doc: PDFDocument) -> [String] {
        var out: [String] = []
        for i in 0 ..< doc.pageCount {
            guard let page = doc.page(at: i), let text = page.string else { continue }
            out.append(contentsOf: text.components(separatedBy: .newlines))
        }
        return out
    }

    private func extractLines(from page: PDFPage) -> [String] {
        #if canImport(Vision) && canImport(AppKit)
        if let extractor = visionExtractor as? VisionPDFTextExtractor {
            let visionLines = extractor.extractLines(from: page)
            if !visionLines.isEmpty {
                return visionLines
            }
        }
        #endif
        return extractRowLines(from: page)
    }

    private func extractRowLines(from page: PDFPage) -> [String] {
        let n = page.numberOfCharacters
        guard n > 0, let pageString = page.string else { return [] }

        let chars = Array(pageString)
        guard chars.count >= n else {
            return pageString.components(separatedBy: .newlines)
        }

        struct CharInfo {
            let char: Character
            let x: CGFloat
            let width: CGFloat
            let y: CGFloat
        }

        var infos: [CharInfo] = []
        infos.reserveCapacity(n)
        for i in 0 ..< n {
            let bounds = page.characterBounds(at: i)
            let ch = chars[i]
            if ch == "\n" || ch == "\r" { continue }
            infos.append(CharInfo(char: ch, x: bounds.origin.x, width: bounds.width, y: bounds.origin.y))
        }

        guard !infos.isEmpty else { return [] }

        // Bucket by Y with 2-point tolerance
        let yTolerance: CGFloat = 2.0
        var buckets: [(y: CGFloat, chars: [CharInfo])] = []
        for info in infos {
            if let idx = buckets.firstIndex(where: { abs($0.y - info.y) <= yTolerance }) {
                buckets[idx].chars.append(info)
            } else {
                buckets.append((y: info.y, chars: [info]))
            }
        }

        // PDF coordinate: origin bottom-left, so larger Y = higher on page = earlier in reading order
        buckets.sort { $0.y > $1.y }

        var lines: [String] = []
        for bucket in buckets {
            let sorted = bucket.chars.sorted { $0.x < $1.x }
            var line = ""
            var lastEndX: CGFloat = -1
            for info in sorted {
                if lastEndX >= 0 {
                    let gap = info.x - lastEndX
                    let avgCharWidth = max(info.width, 1)
                    if gap > avgCharWidth * 0.5 {
                        line += " "
                    }
                }
                line.append(info.char)
                lastEndX = info.x + info.width
            }
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                lines.append(line)
            }
        }
        return lines
    }

    private func parseHDFCTransactions(_ lines: [String]) throws -> [ParsedTransaction] {
        let textParser = HDFCTextBasedParser()
        let reconstructed = textParser.reconstructTransactions(from: lines)
        return textParser.parseToNormalizedTransactions(reconstructed)
    }

    private func extractPeriod(from transactions: [ParsedTransaction]) -> (Date, Date) {
        guard !transactions.isEmpty else {
            let today = Date()
            return (today, today)
        }
        let sorted = transactions.sorted { $0.postedAt < $1.postedAt }
        return (sorted.first!.postedAt, sorted.last!.postedAt)
    }
}

#else
public struct HDFCPDFParser: StatementParser {
    public let supportedFormat: StatementFileFormat = .pdf

    public init(password: String? = nil) {}

    public func parseStatement(from fileURL: URL) async throws -> ParsedStatement {
        throw TransactionImportError.platformUnavailable("PDF parsing not available on this platform")
    }
}
#endif
