import Foundation

/// Runs parser fixtures end-to-end: detects the institution, parses the input file,
/// and diffs the result against the stored golden JSON. Used by the `parser-test` make target.
public struct FixtureRunner: Sendable {
    private let fixtureDirectory: FixtureDirectory

    public init(fixtureDirectory: URL) {
        self.fixtureDirectory = FixtureDirectory(root: fixtureDirectory)
    }

    /// Runs all fixtures found under the fixture directory and returns one `FixtureResult` per file.
    /// Returns an empty array if the fixture directory cannot be enumerated.
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

    /// Parses `fixture.inputURL`, compares against the golden result, and returns the outcome.
    /// A fixture with no `.expected.json` is reported as failed (not yet baselined).
    public func run(fixture: FixtureFile) async -> FixtureResult {
        do {
            let detectedSource = try StatementDetector.detect(fileURL: fixture.inputURL)
            let actual = try UnifiedStatementParser().parse(
                fileURL: fixture.inputURL,
                detectedSource: detectedSource
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

    /// Writes `result` as pretty-printed JSON to `fixture.expectedURL`, creating the file if needed.
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

    /// Loads and decodes the golden `ParseResult` from `fixture.expectedURL`, or returns `nil`.
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

/// The outcome of running a single parser fixture, including both actual and expected results
/// and a list of human-readable diff lines for test reporting.
public struct FixtureResult: Sendable {
    /// The fixture that was run.
    public let fixture: FixtureFile
    /// The actual `ParseResult` produced by the parser, or `nil` if parsing threw.
    public let actual: ParseResult?
    /// The golden `ParseResult` loaded from `.expected.json`, or `nil` if not baselined.
    public let expected: ParseResult?
    /// Human-readable diff lines; empty when `passed == true`.
    public let diff: [String]
    /// `true` when `diff` is empty and a golden result existed to compare against.
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

    /// One-line pass/fail summary for console output.
    public var summary: String {
        let status = passed ? "✓" : "✗"
        return "\(status) \(fixture.institution)/\(fixture.name)"
    }
}
