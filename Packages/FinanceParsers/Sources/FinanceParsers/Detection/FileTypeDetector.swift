import Foundation

public enum FileType: String, Sendable {
    case csv
    case txt
}

public struct FileTypeDetector: Sendable {
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
