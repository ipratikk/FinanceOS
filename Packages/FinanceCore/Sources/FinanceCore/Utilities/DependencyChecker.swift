import Foundation

public enum DependencyChecker {
    private static let ssconvertAvailableKey = "com.financeOS.ssconvertAvailable"

    public static func ensureSSConvertAvailable() async {
        #if os(macOS)
        if isSSConvertAvailable() {
            return
        }

        await installSSConvert()
        #endif
    }

    private static func isSSConvertAvailable() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["ssconvert"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    private static func findBrewExecutable() -> URL? {
        let brewPaths = [
            "/opt/homebrew/bin/brew",
            "/usr/local/bin/brew",
            "/opt/local/bin/brew"
        ]

        for path in brewPaths {
            if FileManager.default.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["brew"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                return URL(fileURLWithPath: path)
            }
        } catch {
            return nil
        }

        return nil
    }

    private static func installSSConvert() async {
        #if os(macOS)
        guard let brewPath = findBrewExecutable() else {
            return
        }

        let process = Process()
        process.executableURL = brewPath
        process.arguments = ["install", "gnumeric"]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return
        }
        #endif
    }
}
