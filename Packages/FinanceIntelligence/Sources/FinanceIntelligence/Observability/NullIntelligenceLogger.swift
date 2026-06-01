import Foundation

/// No-op logger — use in tests and when no persistence is available.
public struct NullIntelligenceLogger: IntelligenceLogger {
    public init() {}
    public func record(_: IntelligenceEvent) async {}
}
