/// Supported file formats that the import pipeline accepts.
public enum StatementFileFormat: String, CaseIterable, Sendable {
    case csv
    case txt
    case xlsx
    case pdf
}
