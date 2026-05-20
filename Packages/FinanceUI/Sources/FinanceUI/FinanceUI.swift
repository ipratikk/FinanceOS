import FinanceCore
import SwiftUI

public protocol FinanceUIModule {
    // Public module marker
}

// MARK: - Tokens

public typealias Colors = AppColors
public typealias Spacing = AppSpacing
public typealias Radius = AppRadius
public typealias Shadow = AppShadows
public typealias Animation = AppAnimation

// MARK: - Re-export all public types

// Colors and design tokens are imported directly
// Typography modifiers are on View via extensions

// Modifiers are public on View via extensions:
// - .cardStyle()
// - .glassStyle()
// - .hoverEffect()
// - .pressEffect()

// Typography modifiers are public on View via extensions:
// - .displayLarge(), .displayMedium()
// - .headingLarge(), .headingMedium()
// - .bodyLarge(), .bodyMedium()
// - .labelSmall()
// - .monoAmount(), .monoAmountSmall()
// - .captionLarge(), .caption()

// Primitives
public typealias Amount = FAmount
public typealias Badge = FBadge
public typealias Label = FLabel

// Components
public typealias Card = FinanceCard
public typealias Metric = MetricCard
public typealias Glass = GlassPanel
public typealias TransactionRow = FDSTransactionRow
public typealias SearchBar = FinanceSearchBar
public typealias Section = SectionHeader
public typealias Empty = EmptyStateView
public typealias Skeleton = LoadingSkeletonView
public typealias Chart = ChartContainer
public typealias Insight = InsightCard

// Picker
public typealias Picker = FDSPicker
public typealias PickerOption = FDSPickerOption
public typealias PickerVariant = FDSPickerVariant

/// Credit Card Display
public typealias CreditCardDisplay = FDSCreditCardDisplay

/// Button
public typealias FinanceButton = FDSLiquidButton

/// Form
public typealias InputField = FDSInputField
public typealias InputState = FDSInputState

/// Feedback
public typealias Banner = FDSBanner
public typealias BannerStyle = FDSBannerStyle

/// Navigation
public typealias Pagination = FDSPagination

/// Onboarding
public typealias CoachTip = FDSCoachTip
public typealias CoachTipStep = FDSCoachTipStep

/// Structural
public typealias AvatarSize = FDSAvatarSize
