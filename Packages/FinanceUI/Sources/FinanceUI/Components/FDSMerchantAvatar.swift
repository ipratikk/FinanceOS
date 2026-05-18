import FinanceCore
import SwiftUI

/// Semantic avatar sizes for the Finance Design System.
public enum FDSAvatarSize {
    case xSmall
    case small
    case medium
    case large
    case hero

    public var value: CGFloat {
        switch self {
        case .xSmall: return 20
        case .small: return 28
        case .medium: return 36
        case .large: return 44
        case .hero: return 64
        }
    }
}

/// Circular merchant/institution avatar.
///
/// Hierarchy:
/// 1. Logo image if available
/// 2. SF Symbol if category-known
/// 3. Tinted initial (first letter, deterministic hue)
///
/// Use for transactions, accounts, cards — anywhere brand recognition matters.
public struct FDSMerchantAvatar: View {
    let name: String
    let symbol: String?
    let imageName: String?
    let size: CGFloat
    let tint: Color

    public init(
        name: String,
        symbol: String? = nil,
        imageName: String? = nil,
        size: CGFloat = 32,
        tint: Color? = nil
    ) {
        self.name = name
        self.symbol = symbol
        self.imageName = imageName
        self.size = size
        self.tint = tint ?? Self.deterministicTint(for: name)
    }

    public init(
        name: String,
        symbol: String? = nil,
        imageName: String? = nil,
        avatarSize: FDSAvatarSize,
        tint: Color? = nil
    ) {
        self.name = name
        self.symbol = symbol
        self.imageName = imageName
        size = avatarSize.value
        self.tint = tint ?? Self.deterministicTint(for: name)
    }

    public var body: some View {
        Group {
            if let imageName, !imageName.isEmpty {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.18)
            } else if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(tint.opacity(0.9))
            } else {
                Text(initial)
                    .font(.system(size: size * 0.42, weight: .semibold, design: .rounded))
                    .foregroundStyle(tint.opacity(0.95))
            }
        }
        .frame(width: size, height: size)
        .background {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay {
                    Circle()
                        .fill(tint.opacity(0.10))
                }
        }
        .overlay {
            Circle()
                .strokeBorder(AppColors.accentGold.opacity(0.1), lineWidth: 0.5)
        }
    }

    private var initial: String {
        String(name.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased()
    }

    private static func deterministicTint(for name: String) -> Color {
        let hues: [Color] = [
            AppColors.accentGold,
            AppColors.accentSlate,
            AppColors.accentIce,
            AppColors.success,
            AppColors.info,
            AppColors.warning,
            AppColors.accentMuted
        ]
        let hash = abs(name.hashValue)
        return hues[hash % hues.count]
    }
}
