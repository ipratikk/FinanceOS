import Foundation

/// Input value type for a single parse operation, bundling the file URL with format
/// and source hints so callers can override auto-detection when the source is already known.
public struct ParseRequest: Sendable {
    /// URL of the statement file to parse.
    public let fileURL: URL
    /// Explicit file format; must match the file's actual content type.
    public let format: StatementFileFormat
    /// Pre-identified source; `nil` triggers auto-detection via `StatementDetector`.
    public let source: StatementSource?
    /// Behavioural knobs for the parse run.
    public let options: ParseOptions

    public init(
        fileURL: URL,
        format: StatementFileFormat,
        source: StatementSource? = nil,
        options: ParseOptions = .default
    ) {
        self.fileURL = fileURL
        self.format = format
        self.source = source
        self.options = options
    }
}

/// Behavioural options forwarded through the parse pipeline.
public struct ParseOptions: Sendable {
    /// Password for encrypted/protected statement files; `nil` for unprotected files.
    public let password: String?
    /// When `true`, parsers emit additional logging for debugging.
    public let verbose: Bool
    /// When `true`, intermediate stage outputs are preserved for inspection.
    public let dumpIntermediateStages: Bool

    public init(
        password: String? = nil,
        verbose: Bool = false,
        dumpIntermediateStages: Bool = false
    ) {
        self.password = password
        self.verbose = verbose
        self.dumpIntermediateStages = dumpIntermediateStages
    }

    /// Default options: no password, non-verbose, no intermediate dumps.
    public static let `default` = ParseOptions()
}
