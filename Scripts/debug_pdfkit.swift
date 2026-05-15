#!/usr/bin/env swift

import Foundation
import PDFKit

guard CommandLine.arguments.count > 1 else {
    print("Usage: debug_pdfkit <pdf_path>")
    exit(1)
}

let pdfPath = CommandLine.arguments[1]
guard let doc = PDFDocument(url: URL(fileURLWithPath: pdfPath)) else {
    print("Error: Cannot open PDF")
    exit(1)
}

print("PDF: \(pdfPath)")
print("Pages: \(doc.pageCount)\n")

// Extract text from first page
if let page = doc.page(at: 0), let text = page.string {
    let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

    print("Page 0: \(lines.count) lines")
    print(String(repeating: "=", count: 60))

    for (i, line) in lines.enumerated().prefix(50) {
        let preview = line.prefix(100)
        print("[\(String(format: "%3d", i))] \(preview)")
    }

    print("\n" + String(repeating: "=", count: 60))
    print("\nSearching for transaction table...")

    for (i, line) in lines.enumerated() {
        if line.contains("Date"), line.contains("Narration") || line.lowercased().contains("narration") {
            print("Table header found at line \(i):")
            print("  \(line)\n")

            print("Next 30 lines from table:")
            for j in (i + 1) ..< min(i + 31, lines.count) {
                let ln = lines[j]
                let isDateLine = ln.trimmingCharacters(in: .whitespaces).range(
                    of: "^\\d{2}/\\d{2}/\\d{2}",
                    options: .regularExpression
                ) != nil
                let marker = isDateLine ? "→" : " "
                print("[\(String(format: "%3d", j))]\(marker) \(ln.prefix(90))")
            }
            break
        }
    }
} else {
    print("Error: Cannot extract text from page 0")
}
