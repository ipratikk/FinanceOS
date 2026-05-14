import Foundation

public enum DependencyChecker {
    private static let ssconvertCheckedKey = "com.financeOS.ssconvertChecked"

    public static func ensureSSConvertAvailable() async {
        #if os(macOS)
        let defaults = UserDefaults.standard

        guard !defaults.bool(forKey: ssconvertCheckedKey) else {
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["ssconvert"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                defaults.set(true, forKey: ssconvertCheckedKey)
                return
            }
        } catch {
            return
        }

        installSSConvert()
        defaults.set(true, forKey: ssconvertCheckedKey)
        #endif
    }

    private static func installSSConvert() {
        #if os(macOS)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/brew")
        process.arguments = ["install", "gnumeric"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return
        }
        #endif
    }
}
