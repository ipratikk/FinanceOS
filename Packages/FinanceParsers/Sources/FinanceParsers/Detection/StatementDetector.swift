import Foundation

/// Errors produced by the file-type and institution detection stages.
public enum DetectionError: Error, CustomStringConvertible {
    /// The file extension or content does not match any known statement format.
    case unrecognizedFormat(String)
    /// The file could not be read from disk.
    case couldNotReadFile(String)

    public var description: String {
        switch self {
        case let .unrecognizedFormat(msg):
            return "Unrecognized statement format: \(msg)"
        case let .couldNotReadFile(msg):
            return "Could not read file: \(msg)"
        }
    }
}

/// Entry point for auto-detection: chains `FileTypeDetector` → `InstitutionDetector`
/// and returns the resolved `StatementSource` for a given file URL.
public struct StatementDetector: Sendable {
    public init() {}

    /// Detects file type then institution, returning the matching `StatementSource`.
    /// Throws `DetectionError` when either stage fails to recognise the file.
    public static func detect(fileURL: URL) throws -> StatementSource {
        let fileType = try FileTypeDetector.detect(fileURL: fileURL)
        return try InstitutionDetector.detect(fileURL: fileURL, fileType: fileType)
    }
}
