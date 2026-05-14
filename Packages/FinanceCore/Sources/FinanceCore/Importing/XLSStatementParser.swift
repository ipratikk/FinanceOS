import Foundation

public struct XLSStatementParser:
    StatementParser,
    Sendable
{
    public let supportedFormat: StatementFileFormat = .xls

    public init() {}

    public func parseStatement(
        from fileURL: URL
    ) async throws -> ParsedStatement {
        let rows = try await extractRows(from: fileURL)
        return try TabularTransactionDecoder.decodeStatement(rows)
    }

    func extractRows(from fileURL: URL) async throws -> [[String]] {
        #if os(macOS)
        let csvData = try convertXLSToCSV(fileURL)
        let csvString = String(data: csvData, encoding: .utf8) ?? ""
        return parseCSVString(csvString)
        #else
        throw TransactionImportError.platformUnavailable(
            "XLS parsing currently supported on macOS only."
        )
        #endif
    }

    #if os(macOS)
    private func convertXLSToCSV(_ fileURL: URL) throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["ssconvert"]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw TransactionImportError.malformedFile(
                "ssconvert not found. Install gnumeric: brew install gnumeric"
            )
        }

        let converter = Process()
        converter.executableURL = URL(fileURLWithPath: "/usr/local/bin/ssconvert")
        converter.arguments = [
            "-S",
            fileURL.path,
            "fd://1"
        ]

        let conversionOutputPipe = Pipe()
        let errorPipe = Pipe()
        converter.standardOutput = conversionOutputPipe
        converter.standardError = errorPipe

        try converter.run()
        converter.waitUntilExit()

        let outputData = conversionOutputPipe.fileHandleForReading.readDataToEndOfFile()

        guard converter.terminationStatus == 0 else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw TransactionImportError.malformedFile(
                "XLS conversion failed: \(errorMessage)"
            )
        }

        return outputData
    }

    private func parseCSVString(_ csvString: String) -> [[String]] {
        let lines = csvString.components(separatedBy: .newlines)
        return lines
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { line in
                line.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
            }
    }
    #endif
}
