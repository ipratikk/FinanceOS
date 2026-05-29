import FinanceParsers
import Foundation
import UniformTypeIdentifiers

public extension StatementFileFormat {
    /// Maps each format to its UTType for use in `UIDocumentPickerViewController` / `fileImporter`.
    var utType: UTType {
        switch self {
        case .csv:
            return .commaSeparatedText
        case .txt:
            return .plainText
        case .pdf:
            return .pdf
        case .xlsx:
            return UTType(filenameExtension: "xlsx") ?? .data
        }
    }
}
