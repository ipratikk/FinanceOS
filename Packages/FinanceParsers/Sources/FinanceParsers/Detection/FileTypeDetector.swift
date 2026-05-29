import Foundation

/// Supported raw file types that the parser pipeline can process.
public enum FileType: String, Sendable {
    case csv
    case txt
}

/// Detects the file type of a statement from its path extension.
/// Only inspects the URL; it does not read file contents.
public struct FileTypeDetector: Sendable {
    /// Returns the `FileType` matching the URL's extension.
    /// Throws `DetectionError.unrecognizedFormat` for unsupported extensions.
    public static func detect(fileURL: URL) throws -> FileType {
        let pathExtension = fileURL.pathExtension.lowercased()

        switch pathExtension {
        case "csv":
            return .csv
        case "txt":
            return .txt
        default:
            throw DetectionError.unrecognizedFormat("Unknown file extension: \(pathExtension)")
        }
    }
}
