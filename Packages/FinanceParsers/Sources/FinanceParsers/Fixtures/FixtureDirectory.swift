import Foundation

/// Scans a directory tree of parser test fixtures, pairing each input statement file
/// with its optional `.expected.json` golden result. The tree is structured as
/// `<root>/<institution>/<inputFile>` with a sibling `<inputFile>.expected.json`.
public struct FixtureDirectory: Sendable {
    /// Root directory containing institution sub-directories.
    public let root: URL

    public init(root: URL) {
        self.root = root
    }

    /// Enumerates all input files under `root`, pairing each with its expected-result file if present.
    /// Returns fixtures sorted by institution name for stable test ordering.
    public func fixtureFiles() throws -> [FixtureFile] {
        let fileManager = FileManager.default
        var fixtures: [FixtureFile] = []

        let institutionDirs = try fileManager.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        for institutionDir in institutionDirs {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: institutionDir.path, isDirectory: &isDirectory),
                  isDirectory.boolValue
            else {
                continue
            }

            let institution = institutionDir.lastPathComponent

            let files = try fileManager.contentsOfDirectory(
                at: institutionDir,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )

            var inputFiles = Set<String>()
            var expectedFiles = Set<String>()

            for file in files {
                let filename = file.lastPathComponent
                if filename.hasSuffix(".expected.json") {
                    let baseName = String(filename.dropLast(".expected.json".count))
                    expectedFiles.insert(baseName)
                } else {
                    inputFiles.insert(filename)
                }
            }

            for inputFile in inputFiles {
                let inputURL = institutionDir.appendingPathComponent(inputFile)
                let expectedURL = institutionDir.appendingPathComponent("\(inputFile).expected.json")

                let expectedFileExists = fileManager.fileExists(atPath: expectedURL.path)

                let fixture = FixtureFile(
                    inputURL: inputURL,
                    expectedURL: expectedFileExists ? expectedURL : nil,
                    institution: institution,
                    name: inputFile
                )

                fixtures.append(fixture)
            }
        }

        return fixtures.sorted { $0.institution < $1.institution }
    }
}

/// A single parser test fixture: the input statement file and its optional golden `ParseResult`.
public struct FixtureFile: Sendable {
    /// URL of the raw statement file used as parser input.
    public let inputURL: URL
    /// URL of the `.expected.json` golden result, or `nil` if no baseline exists yet.
    public let expectedURL: URL?
    /// Institution sub-directory name, e.g. `"hdfc"` or `"icici"`.
    public let institution: String
    /// Filename of the input file, used for display and test identification.
    public let name: String

    public init(
        inputURL: URL,
        expectedURL: URL?,
        institution: String,
        name: String
    ) {
        self.inputURL = inputURL
        self.expectedURL = expectedURL
        self.institution = institution
        self.name = name
    }
}
