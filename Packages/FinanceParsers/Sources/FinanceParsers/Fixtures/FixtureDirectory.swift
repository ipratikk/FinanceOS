import Foundation

public struct FixtureDirectory: Sendable {
    public let root: URL

    public init(root: URL) {
        self.root = root
    }

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
                  isDirectory.boolValue else {
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

public struct FixtureFile: Sendable {
    public let inputURL: URL
    public let expectedURL: URL?
    public let institution: String
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
