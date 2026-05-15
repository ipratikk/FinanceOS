import Foundation

public enum DependencyChecker {
    private static let ssconvertAvailableKey = "com.financeOS.ssconvertAvailable"
    private static let dependencyInstallApprovedKey = "com.financeOS.dependencyInstallApproved"

    public static func ensureSSConvertAvailable(permissionHandler: (String) async -> Bool = { _ in true }) async {
        #if os(macOS)
        if isSSConvertAvailable() {
            return
        }

        let approved = await permissionHandler(
            "FinanceOS needs to install ssconvert to parse Excel files. This requires Homebrew installation. Proceed?"
        )

        if approved {
            await installSSConvert()
        }
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

    private static func isBrewInstalled() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", "which brew"]

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

    private static func installBrew() async {
        #if os(macOS)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [
            "-c",
            "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        ]

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus != 0 {
                return
            }
        } catch {
            return
        }
        #endif
    }

    private static func installSSConvert() async {
        #if os(macOS)
        if !isBrewInstalled() {
            await installBrew()
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", "eval \"$(/opt/homebrew/bin/brew shellenv)\" && brew install gnumeric"]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        let environment = ProcessInfo.processInfo.environment
        var processEnv = environment
        // Add common Homebrew paths to ensure brew is found
        let brewPaths = ["/opt/homebrew/bin", "/usr/local/bin"]
        let currentPath = environment["PATH"] ?? ""
        let newPath = brewPaths.filter { !currentPath.contains($0) }.joined(separator: ":") + ":" + currentPath
        processEnv["PATH"] = newPath

        process.environment = processEnv

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return
        }
        #endif
    }
}
