import Foundation

public enum FDSBreakpoint: Equatable, Sendable {
    /// < 1200pt — small window or constrained display
    case compact
    /// 1200–1800pt — MacBook 13"/14" (base scale = 1.0)
    case regular
    /// 1800–2400pt — MacBook Pro 16", iMac 24"
    case large
    /// > 2400pt — iMac 27", Studio Display, Pro Display XDR
    case xlarge

    public init(screenWidth: CGFloat) {
        switch screenWidth {
        case ..<1200: self = .compact
        case 1200 ..< 1800: self = .regular
        case 1800 ..< 2400: self = .large
        default: self = .xlarge
        }
    }

    public var typographyScale: CGFloat {
        switch self {
        case .compact: return 0.875
        case .regular: return 1.0
        case .large: return 1.1
        case .xlarge: return 1.2
        }
    }

    public var spacingScale: CGFloat {
        switch self {
        case .compact: return 0.875
        case .regular: return 1.0
        case .large: return 1.125
        case .xlarge: return 1.25
        }
    }
}
