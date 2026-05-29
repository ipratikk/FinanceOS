import FinanceParsers
import Foundation

public extension StatementFileFormat {
    /// Infers file format from the URL's path extension; defaults to `.csv` for unknown extensions.
    static func detect(from url: URL) -> StatementFileFormat {
        let pathExtension = url.pathExtension.lowercased()

        switch pathExtension {
        case "csv":
            return .csv
        case "txt":
            return .txt
        case "xlsx":
            return .xlsx
        case "pdf":
            return .pdf
        default:
            return .csv
        }
    }
}
