import Foundation

public struct ParseRequest: Sendable {
    public let fileURL: URL
    public let format: StatementFileFormat
    public let source: StatementSource?
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

public struct ParseOptions: Sendable {
    public let password: String?
    public let verbose: Bool
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

    public static let `default` = ParseOptions()
}
