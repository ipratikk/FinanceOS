import Foundation

enum CLIProgressReporter {
    static func report(_ message: String) {
        fputs("✓ \(message)\n", stdout)
    }

    static func error(_ message: String) {
        fputs("✗ \(message)\n", stderr)
    }
}
