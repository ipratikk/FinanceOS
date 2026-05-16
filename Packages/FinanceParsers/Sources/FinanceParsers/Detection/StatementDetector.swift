import Foundation

public enum DetectionError: Error, CustomStringConvertible {
    case unrecognizedFormat(String)
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

public struct StatementDetector: Sendable {
    public init() {}

    public static func detect(fileURL: URL) throws -> StatementSource {
        let fileType = try FileTypeDetector.detect(fileURL: fileURL)
        return try InstitutionDetector.detect(fileURL: fileURL, fileType: fileType)
    }
}
