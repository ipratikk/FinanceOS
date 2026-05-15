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
        guard let ssconvertPath = findSSConvert() else {
            throw TransactionImportError.malformedFile(
                "ssconvert not found. Install gnumeric: brew install gnumeric"
            )
        }

        let converter = Process()
        converter.executableURL = ssconvertPath
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

    private func findSSConvert() -> URL? {
        let commonPaths = [
            "/opt/homebrew/bin/ssconvert",
            "/usr/local/bin/ssconvert",
            "/opt/local/bin/ssconvert"
        ]

        for path in commonPaths {
            if FileManager.default.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["ssconvert"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    return URL(fileURLWithPath: path)
                }
            }
        } catch {
            return nil
        }

        return nil
    }
    #endif
}
