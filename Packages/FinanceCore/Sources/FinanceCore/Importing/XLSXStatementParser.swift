//
//  XLSXStatementParser.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation

#if canImport(FoundationXML)
import FoundationXML
#endif

public struct XLSXStatementParser:
    StatementParser,
    Sendable
{
    public let supportedFormat: StatementFileFormat = .xlsx

    public init() {}

    public func parseStatement(
        from fileURL: URL
    ) async throws -> ParsedStatement {
        let rows = try await extractRows(from: fileURL)
        return try TabularTransactionDecoder.decodeStatement(rows)
    }

    func extractRows(from fileURL: URL) async throws -> [[String]] {
        #if os(macOS)
        let workbook = try XLSXWorkbookReader.readWorkbook(
            at: fileURL
        )
        return workbook.rows
        #else
        throw TransactionImportError.platformUnavailable(
            "XLSX parsing currently supported on macOS only."
        )
        #endif
    }
}

#if os(macOS)
private enum XLSXWorkbookReader {
    static func readWorkbook(
        at fileURL: URL
    ) throws -> ParsedWorkbook {
        let sharedStringsXML = try unzipEntry(
            "xl/sharedStrings.xml",
            from: fileURL
        )
        let worksheetXML = try unzipEntry(
            "xl/worksheets/sheet1.xml",
            from: fileURL
        )

        let sharedStrings = try sharedStringsXML.map(parseSharedStrings) ?? []
        let rows = try parseWorksheetRows(
            worksheetXML,
            sharedStrings: sharedStrings
        )

        return ParsedWorkbook(rows: rows)
    }

    private static func unzipEntry(
        _ entryPath: String,
        from fileURL: URL
    ) throws -> Data? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-p", fileURL.path, entryPath]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let output = outputPipe.fileHandleForReading.readDataToEndOfFile()

        if process.terminationStatus == 0 {
            return output.isEmpty ? nil : output
        }

        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let errorText = String(data: errorData, encoding: .utf8) ?? "Unknown unzip error"

        if errorText.contains("filename not matched") {
            return nil
        }

        throw TransactionImportError.malformedFile(errorText)
    }

    private static func parseSharedStrings(
        _ data: Data
    ) throws -> [String] {
        let delegate = SharedStringsParserDelegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate

        guard parser.parse() else {
            throw TransactionImportError.malformedFile(
                parser.parserError?.localizedDescription ?? "Unable to parse shared strings."
            )
        }

        return delegate.strings
    }

    private static func parseWorksheetRows(
        _ data: Data?,
        sharedStrings: [String]
    ) throws -> [[String]] {
        guard let data else {
            throw TransactionImportError.malformedFile(
                "Missing worksheet XML in XLSX file."
            )
        }

        let delegate = WorksheetParserDelegate(
            sharedStrings: sharedStrings
        )
        let parser = XMLParser(data: data)
        parser.delegate = delegate

        guard parser.parse() else {
            throw TransactionImportError.malformedFile(
                parser.parserError?.localizedDescription ?? "Unable to parse worksheet."
            )
        }

        return delegate.rows
    }
}

private struct ParsedWorkbook {
    let rows: [[String]]
}

private final class SharedStringsParserDelegate:
    NSObject,
    XMLParserDelegate
{
    private(set) var strings: [String] = []

    private var currentText = ""
    private var insideTextNode = false

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        if elementName == "t" {
            insideTextNode = true
            currentText = ""
        }
    }

    func parser(
        _ parser: XMLParser,
        foundCharacters string: String
    ) {
        if insideTextNode {
            currentText.append(string)
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if elementName == "t" {
            strings.append(currentText)
            insideTextNode = false
        }
    }
}

private final class WorksheetParserDelegate:
    NSObject,
    XMLParserDelegate
{
    private let sharedStrings: [String]

    private(set) var rows: [[String]] = []

    private var currentRow: [Int: String] = [:]
    private var currentColumnIndex = 0
    private var currentCellType: String?
    private var currentValue = ""
    private var insideValueNode = false

    init(
        sharedStrings: [String]
    ) {
        self.sharedStrings = sharedStrings
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        switch elementName {
        case "row":
            currentRow = [:]

        case "c":
            currentCellType = attributeDict["t"]
            currentColumnIndex = columnIndex(
                from: attributeDict["r"] ?? ""
            )
            currentValue = ""

        case "v", "t":
            insideValueNode = true
            currentValue = ""

        default:
            break
        }
    }

    func parser(
        _ parser: XMLParser,
        foundCharacters string: String
    ) {
        if insideValueNode {
            currentValue.append(string)
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        switch elementName {
        case "v", "t":
            insideValueNode = false

        case "c":
            currentRow[currentColumnIndex] = decodedCellValue()
            currentCellType = nil

        case "row":
            let maxIndex = currentRow.keys.max() ?? -1
            if maxIndex >= 0 {
                let row = (0 ... maxIndex).map { currentRow[$0] ?? "" }
                rows.append(row)
            }

        default:
            break
        }
    }

    private func decodedCellValue() -> String {
        if currentCellType == "s",
           let sharedStringIndex = Int(currentValue),
           sharedStrings.indices.contains(sharedStringIndex)
        {
            return sharedStrings[sharedStringIndex]
        }

        return currentValue
    }

    private func columnIndex(
        from cellReference: String
    ) -> Int {
        let letters = cellReference.prefix { $0.isLetter }
        guard !letters.isEmpty else {
            return 0
        }

        var index = 0

        for letter in letters.uppercased() {
            guard let ascii = letter.asciiValue else {
                continue
            }

            index = index * 26 + Int(ascii - 64)
        }

        return max(index - 1, 0)
    }
}
#endif
