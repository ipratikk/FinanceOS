---
name: fds-reference
description: Finance Design System (FDS) component reference for FinanceOS SwiftUI. Maps native SwiftUI to FDS equivalents, documents AppColors/AppSpacing/AppTypography tokens. Claude-only knowledge skill — auto-loads when writing SwiftUI views.
user-invocable: false
---

# FDS Reference

Use this as the source of truth when writing or reviewing SwiftUI in FinanceOS.
All components live in `Packages/FinanceUI/Sources/FinanceUI/Components/`.
All tokens live in `Packages/FinanceCore/Sources/FinanceCore/Design/`.

---

## Component Mapping (STRICT)

Always prefer FDS components over native SwiftUI equivalents:

| Use case | FDS Component | Never use |
|----------|---------------|-----------|
| Currency / monetary amounts | `FDSAmount` | bare `Text` for amounts |
| Transaction row in a list | `FDSTransactionRow` | custom HStack |
| Account/card chip | `FDSAccountChip` | custom label |
| Bank logo/mark | `FDSBankMark` | `Image` directly |
| Merchant avatar | `FDSMerchantAvatar` | `AsyncImage` |
| Network logo (Visa, Mastercard) | `FDSNetworkLogo` | `Image` directly |
| Card art display | `FDSCardArt` | `RoundedRectangle` + color |
| Credit card display | `FDSCreditCardDisplay` | custom card view |
| Category icon | `FDSCategoryGlyph` | `Image(systemName:)` for categories |
| Text input | `FDSTextInput` or `FDSInputField` | `TextField` |
| Selection field | `FDSField` / `FDSSelect` | `Picker` |
| Picker row | `FDSPickerRow` / `FDSPickerOption` | custom row |
| Choice group (radio-style) | `FDSChoiceGroup` | custom toggle group |
| Radio button | `FDSRadio` | `Toggle` |
| Toggle | `FDSToggle` | `Toggle` (use FDS wrapper for consistent styling) |
| Stepper | `FDSStepper` | `Stepper` |
| Bottom sheet | `FDSSheet` | `.sheet` modifier directly |
| Banner / alert strip | `FDSBanner` | custom HStack |
| Empty state | `FDSEmptyState` | custom VStack |
| Error state | `FDSErrorState` | custom VStack |
| Coach tip / tooltip | `FDSCoachTip` | `popover` modifier |
| Card container | `FDSCard` | `RoundedRectangle` background |
| Section header | `FDSSectionHeader` | `Text` with `.font(.headline)` |
| List row | `FDSListRow` | custom HStack |
| Sidebar item | `FDSSidebarItem` | custom NavigationLink label |
| Chip / tag | `FDSChip` | `Capsule` background |
| Metric tile | `FDSMetricTile` | custom VStack |
| Insight card | `InsightCard` | custom card |
| Metric card | `MetricCard` | custom card |
| Pagination dots | `FDSPagination` | custom HStack of circles |
| Swatch picker | `FDSSwatchPicker` | custom color grid |
| Glass surface | `FDSGlassSurface` / `GlassPanel` | `.ultraThinMaterial` directly |
| Image display | `FDSImage` | `Image` + `.resizable()` chain |
| Label / tag | `FDSLabel` | `Text` + background modifier |
| Liquid button | `FDSLiquidButton` | custom `Button` |
| Accessible icon button | `AccessibleIconButton` | `Button { Image(...) }` |
| Search bar | `FinanceSearchBar` | `SearchBar` or `TextField` |
| Loading skeleton | `LoadingSkeletonView` | `ProgressView` |
| Chart wrapper | `ChartContainer` | `Chart` without wrapper |
| Wallpaper/background | `Wallpaper` | `Color(...)` as background |

---

## Color Tokens — `AppColors`

**Never hardcode hex colors.** Always use `AppColors.*`.

### Backgrounds
```swift
AppColors.base      // #0f0f12 — main app background
AppColors.surface   // #1e1e21 — primary card/surface
AppColors.surface2  // #292a2b — elevated surface
AppColors.surface3  // #333537 — top elevation (modals, sheets)
```

### Accents
```swift
AppColors.accent        // emerald green — primary action color
AppColors.accentGreen   // #30D158
AppColors.accentOrange  // #FF9F0A — secondary/warning
AppColors.accentBlue    // #0A84FF
AppColors.accentPurple  // #BF5AF2
AppColors.accentMuted   // #8E8E93 — muted gray
```

### Semantic
```swift
AppColors.success   // positive / credit transactions
AppColors.danger    // negative / debit transactions
AppColors.warning   // caution state
AppColors.info      // informational (= accentBlue)
AppColors.credit    // alias for success
AppColors.debit     // alias for danger
```

### Text
```swift
AppColors.textPrimary    // white
AppColors.textSecondary  // #A1A1A6
AppColors.textTertiary   // #8E8E93
```

### Borders
```swift
AppColors.border        // 8% opacity — standard border
AppColors.borderAccent  // 12% opacity — accent border
AppColors.borderSubtle  // 5% opacity — minimal separator
```

---

## Spacing Tokens — `AppSpacing`

Use 8pt-aligned aliases for new views:

```swift
AppSpacing.tight    // 4pt — micro gaps
AppSpacing.compact  // 8pt — tight spacing
AppSpacing.md       // 16pt — standard padding
AppSpacing.xl       // 24pt — section gaps
AppSpacing.xxl      // 32pt — large gaps
AppSpacing.section  // 48pt — major section separation

// Layout constants
AppSpacing.hitTarget         // 44pt — min touch target
AppSpacing.Layout.sidebarWidth  // 232pt — standard sidebar
```

Prefer `AppSpacing.*` over `AppSpacing.sm` / `AppSpacing.lg` (legacy, kept for backward compat).

---

## Typography Tokens — `AppTypography`

```swift
// Display (hero, marketing)
AppTypography.displayLarge    // 34pt bold
AppTypography.displaySmall    // 22pt bold

// Headings
AppTypography.headingXL       // 24pt bold
AppTypography.headingLg       // 20pt bold
AppTypography.headingMd       // 18pt semibold
AppTypography.headingSmall    // 16pt semibold
AppTypography.subheadline     // 15pt semibold

// Body
AppTypography.bodyLg          // 16pt regular
AppTypography.bodyMd          // 14pt regular
AppTypography.bodyMdSemibold  // 14pt semibold
AppTypography.bodySm          // 13pt regular
AppTypography.bodySmSemibold  // 13pt semibold

// Labels & Captions
AppTypography.labelSemibold   // 13pt semibold
AppTypography.labelSmall      // 12pt regular
AppTypography.captionLg       // 12pt regular
AppTypography.captionSm       // 11pt regular
```

---

## Architecture Rules for UI

- Views live in `Apps/FinanceOSMac/` — never in Packages
- FDS components live in `Packages/FinanceUI/` — no business logic
- ViewModels own state — never embed `@State` business logic in views
- Do not import GRDB in any View or ViewModel directly
- `AppContainer` is the composition root — inject dependencies there

## When component doesn't exist in FDS

Check `Packages/FinanceUI/Sources/FinanceUI/Components/` first.
If genuinely absent, use native SwiftUI and add a `// TODO: FDS candidate` comment.
Do not create a new FDS component without first discussing the addition.
