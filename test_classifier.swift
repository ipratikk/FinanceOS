#!/usr/bin/env swift

import Foundation

// Add FinanceParsers to the search path
let fileManager = FileManager.default
let repoRoot = "/Users/pragoel/Documents/GitHub/FinanceOS"
let parsersPath = "\(repoRoot)/Packages/FinanceParsers/Sources/FinanceParsers"

// Read the source files we need
let classifierPath = "\(parsersPath)/HDFCLineClassifier.swift"
let modelsPath = "\(parsersPath)/HDFCModels.swift"

print("Testing line classification on PDF extract...")
print("=" * 60)

/// For now, just read a sample PDF and show text extraction
let pdfPath = "/Users/pragoel/Documents/Acct_Statement_XXXXXXXX6521_15052026.pdf"

if let pdfURL = URL(string: "file://" + pdfPath),
   let doc = PDFDocument(url: pdfURL)
{
    var allLines: [String] = []
    for i in 0 ..< doc.pageCount {
        if let page = doc.page(at: i),
           let text = page.string
        {
            allLines += text.components(separatedBy: .newlines)
        }
    }

    // Find header
    if let headerIdx = allLines.firstIndex(where: {
        $0.lowercased().contains("date") && $0.lowercased().contains("narration")
    }) {
        let tableLines = Array(allLines[headerIdx ..< min(headerIdx + 50, allLines.count)])

        print("First 50 lines from transaction table:")
        for (i, line) in tableLines.enumerated() {
            print("[\(i)] \(line)")
        }
    }
} else {
    print("Error: Could not open PDF")
}
