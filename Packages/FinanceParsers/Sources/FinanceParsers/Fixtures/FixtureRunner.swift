import Foundation

public struct FixtureRunner: Sendable {
    private let fixtureDirectory: FixtureDirectory

    public init(fixtureDirectory: URL) {
        self.fixtureDirectory = FixtureDirectory(root: fixtureDirectory)
    }

    public func runAll() async -> [FixtureResult] {
        do {
            let fixtures = try fixtureDirectory.fixtureFiles()
            var results: [FixtureResult] = []

            for fixture in fixtures {
                let result = await run(fixture: fixture)
                results.append(result)
            }

            return results
        } catch {
            return []
        }
    }

    public func run(fixture: FixtureFile) async -> FixtureResult {
        let fileExtension = fixture.inputURL.pathExtension.lowercased()
        guard let format = StatementFileFormat(rawValue: fileExtension) else {
            return FixtureResult(
                fixture: fixture,
                actual: nil,
                expected: nil,
                diff: ["Unsupported file format: \(fileExtension)"],
                passed: false
            )
        }

        do {
            let parser: StatementParser = {
                switch format {
                case .pdf:
                    return HDFCPDFParser()
                case .csv:
                    return CSVStatementParser()
                case .txt:
                    return TXTStatementParser()
                case .xlsx:
                    return XLSXStatementParser()
                }
            }()

            let statement = try await parser.parseStatement(from: fixture.inputURL)

            let institutionVersion = institutionVersionForInstitution(fixture.institution)
            let actual = ParseResult(
                institutionVersion: institutionVersion,
                statement: statement,
                diagnostics: ParserDiagnostics()
            )

            let expected = try loadExpectedResult(fixture: fixture)
            let diff = ParseResultDiffer.compare(actual, expected)
            let passed = diff.isEmpty && expected != nil

            return FixtureResult(
                fixture: fixture,
                actual: actual,
                expected: expected,
                diff: diff,
                passed: passed
            )
        } catch let error as TransactionImportError {
            return FixtureResult(
                fixture: fixture,
                actual: nil,
                expected: try? loadExpectedResult(fixture: fixture),
                diff: [error.description],
                passed: false
            )
        } catch {
            return FixtureResult(
                fixture: fixture,
                actual: nil,
                expected: try? loadExpectedResult(fixture: fixture),
                diff: [error.localizedDescription],
                passed: false
            )
        }
    }

    public func updateExpected(fixture: FixtureFile, with result: ParseResult) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(result)

        guard let expectedURL = fixture.expectedURL else {
            let expectedURL = fixture.inputURL.deletingPathExtension()
                .appendingPathExtension("expected.json")
            try data.write(to: expectedURL)
            return
        }

        try data.write(to: expectedURL)
    }

    private func loadExpectedResult(fixture: FixtureFile) throws -> ParseResult? {
        guard let expectedURL = fixture.expectedURL else {
            return nil
        }

        let data = try Data(contentsOf: expectedURL)
        let decoder = JSONDecoder()
        return try decoder.decode(ParseResult.self, from: data)
    }

    private func institutionVersionForInstitution(_ institution: String) -> String {
        let normalized = institution.lowercased()
        switch normalized {
        case "hdfc":
            return "HDFC-1.0"
        case "icici":
            return "ICICI-1.0"
        case "amex":
            return "Amex-1.0"
        default:
            return "unknown-1.0"
        }
    }
}

public struct FixtureResult: Sendable {
    public let fixture: FixtureFile
    public let actual: ParseResult?
    public let expected: ParseResult?
    public let diff: [String]
    public let passed: Bool

    public init(
        fixture: FixtureFile,
        actual: ParseResult?,
        expected: ParseResult?,
        diff: [String],
        passed: Bool
    ) {
        self.fixture = fixture
        self.actual = actual
        self.expected = expected
        self.diff = diff
        self.passed = passed
    }

    public var summary: String {
        let status = passed ? "✓" : "✗"
        return "\(status) \(fixture.institution)/\(fixture.name)"
    }
}
