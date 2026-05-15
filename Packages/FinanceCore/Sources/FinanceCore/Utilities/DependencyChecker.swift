import Foundation

public struct DependencyStep: Identifiable, Sendable {
    public let id: UUID
    public let label: String
    public var status: StepStatus
    public var logLines: [String]

    public init(label: String, status: StepStatus, logLines: [String] = []) {
        self.id = UUID()
        self.label = label
        self.status = status
        self.logLines = logLines
    }
}

public enum StepStatus: Sendable {
    case pending
    case running
    case done
    case failed(String)
}

public enum DependencyChecker {
    private static let ssconvertAvailableKey = "com.financeOS.ssconvertAvailable"
    private static let dependencyInstallApprovedKey = "com.financeOS.dependencyInstallApproved"

    public static func isSSConvertAvailable() -> Bool {
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

    public static func ensureSSConvertAvailable(progressHandler: @escaping (DependencyStep) async -> Void = { _ in }) async {
        #if os(macOS)
        var step1 = DependencyStep(label: "Checking for ssconvert", status: .running)
        await progressHandler(step1)

        if isSSConvertAvailable() {
            step1.status = .done
            await progressHandler(step1)
            return
        }

        var step2 = DependencyStep(label: "Checking for Homebrew", status: .running)
        await progressHandler(step2)

        if isBrewInstalled() {
            step2.status = .done
            await progressHandler(step2)
        } else {
            step2.status = .failed("Homebrew not found")
            await progressHandler(step2)

            var step3 = DependencyStep(label: "Installing Homebrew", status: .running)
            await progressHandler(step3)
            await installBrew()
            step3.status = .done
            await progressHandler(step3)
        }

        _ = await installSSConvert(progressHandler: progressHandler)

        var step5 = DependencyStep(label: "Verifying ssconvert", status: .running)
        await progressHandler(step5)

        if isSSConvertAvailable() {
            step5.status = .done
            await progressHandler(step5)
        } else {
            step5.status = .failed("ssconvert not found after install")
            await progressHandler(step5)
        }
        #endif
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

    private static func installSSConvert(progressHandler: @escaping (DependencyStep) async -> Void) async -> Bool {
        #if os(macOS)
        guard let brewPath = findBrewExecutable() else {
            let failedStep = DependencyStep(label: "Installing gnumeric", status: .failed("brew not found"))
            await progressHandler(failedStep)
            return false
        }

        let process = Process()
        process.executableURL = brewPath
        process.arguments = ["install", "gnumeric"]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        let linesLock = NSLock()
        var lines: [String] = []

        do {
            try process.run()

            let fileHandle = outputPipe.fileHandleForReading
            fileHandle.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty, let line = String(data: data, encoding: .utf8) {
                    let trimmed = line.trimmingCharacters(in: .newlines)
                    if !trimmed.isEmpty {
                        linesLock.lock()
                        lines.append(trimmed)
                        let lineCopy = lines
                        linesLock.unlock()

                        let step = DependencyStep(label: "Installing gnumeric", status: .running, logLines: lineCopy)
                        Task { @MainActor in
                            await progressHandler(step)
                        }
                    }
                }
            }

            process.waitUntilExit()
            fileHandle.readabilityHandler = nil

            return process.terminationStatus == 0
        } catch {
            let failedStep = DependencyStep(label: "Installing gnumeric", status: .failed("Process error"))
            await progressHandler(failedStep)
            return false
        }
        #else
        return false
        #endif
    }
}
