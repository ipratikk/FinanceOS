# FinanceUI

SwiftUI design system for FinanceOS. Composed of tokens (colors, typography, spacing, shadows, materials) + reusable components (buttons, cards, badges, glass surfaces).

## Architecture

- **Canonical tokens:** `FinanceCore/Design/App*.swift` (AppColors, AppSpacing, AppRadius, AppShadows, AppAnimation, AppTypography)
- **FinanceUI-specific overrides:** `Design/DesignTokens.swift` (semantic colors, typography variants, elevation aliases)
- **Components:** 40+ FDS-prefixed components (FDSLiquidButton, FDSTransactionRow, etc.) + public typealiases for clean API
- **Modifiers:** Glass materials, gleam effects, interaction states (hover/press)

## Token Taxonomy

### Colors

| Category | File | Purpose |
|----------|------|---------|
| **System** | `FinanceCore/AppColors.swift` | Apple system colors (red, orange, yellow, green, mint, teal, cyan, blue, indigo, purple, pink, brown, gray) |
| **Semantic** | `DesignTokens.Semantic` | Functional colors (credit=green, debit=red, danger, warning, info, success, error) |
| **Text** | `DesignTokens.Text` | Text hierarchy (primary #F1F3F6, secondary #BDC2CC, tertiary #858A94, quaternary #555A64) |
| **Background** | `DesignTokens.Background` | Surface tints (base, surface, surface2, surfaceGlass, surfaceGlassThin) |

### Typography

| Level | File | Usage |
|-------|------|-------|
| **Headline** | `AppTypography` | Screen titles, section headers (size 24–30pt) |
| **Body** | `AppTypography` | Main content text (size 14–16pt) |
| **Caption** | `AppTypography` | Small labels, annotations (size 10–12pt) |
| **Mono** | `AppTypography` | Amounts, codes, monospaced (JetBrains Mono) |
| **View extensions** | `AppTypography+Extensions.swift` | Preferred consumption method (`.bodyLarge()`, `.captionSmall()`, `.monoAmount()`) |

### Spacing

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4pt | Hairline gaps, icon padding |
| `sm` | 8pt | Dense layouts, interior padding |
| `md` | 12pt | Standard padding, medium gaps |
| `lg` | 16pt | Container padding, section spacing |
| `xl` | 24pt | Large sections |
| `xxl` | 32pt | Screen margins |

Source: `AppSpacing` (FinanceCore). Density modes: `DesignTokens.Density.standard` (default) or `.compact` (70% of standard values).

### Radius

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4pt | Hairline corners, small pill badges |
| `sm` | 6pt | Button corners, small cards |
| `md` | 8pt | Standard cards, medium containers |
| `lg` | 12pt | Large cards, prominent surfaces |
| `xl` | 16pt | Hero sections, full-screen sheets |
| `xxl` | 24pt | Edge-to-edge corners |

Source: `AppRadius` (FinanceCore).

### Shadows

| Tier | File | Usage |
|------|------|-------|
| **lift-1 / subtle** | `AppShadows.subtle` | Hover state, light elevation |
| **lift-2 / standard** | `AppShadows.standard` | Resting card elevation |
| **lift-3 / elevated** | `AppShadows.elevated` | Modal/sheet elevation |
| **prominent** | `AppShadows.prominent` | Menu/popover elevation |

Apply via `.shadow(AppShadows.standard.shadow)` or use glass materials (which bake in appropriate shadows).

### Glass Materials

| Tier | Material | Blur | Tint | Usage |
|------|----------|------|------|-------|
| **thin** | `.ultraThinMaterial` | 20px | +4% white | Subtle backgrounds |
| **standard** | `.regularMaterial` | 40px | +6% white | Default glass surfaces, buttons |
| **strong** | `.thickMaterial` | 60px | +9% white | Prominent cards, modals |

Modifiers: `.glassSurface()` (auto material + elevation), `.glassPill()` (capsule glass + gleam).

### Animation

| Name | Duration | Curve | Usage |
|------|----------|-------|-------|
| `selection` | 250ms | spring(0.25, 0.82) | Menu selection, nav |
| `springSnappy` | 300ms | spring(0.3, 0.8) | Bounce effects |
| `springBouncy` | 450ms | spring(0.45, 0.72) | Playful animations |
| `easeSmooth` | 220ms | easeInOut | Standard transitions |
| `easeFast` | 140ms | easeOut | Quick feedback |
| `hover` | 120ms | easeOut | Micro-interactions |

Source: `AppAnimation` (FinanceCore).

---

## Component Catalog

### Public Typealiases (preferred consumption)

```swift
// Containers
Card = FDSCard
Glass = FDSGlassSurface
Panel = FDSPanel

// Controls
FinanceButton = FDSLiquidButton
Picker = FDSPicker
Field = FDSField

// Data display
TransactionRow = FDSTransactionRow
Badge = FBadge
Amount = FAmount

// Semantic
Label = FLabel
Section = FDSSection
Metric = FDSMetric
```

All public components live in `Components/` or `Primitives/`.

### Component Details

| Component | File | Props | Notes |
|-----------|------|-------|-------|
| `FinanceButton` | `FDSLiquidButton.swift` | `label`, `variant` (primary/secondary/danger/link), `action` | Glass pill with gleam; `.regularMaterial` |
| `TransactionRow` | `FDSTransactionRow.swift` | `merchant`, `subtitle`, `amount`, `isDebit`, `accountChip`, `runningBalance`, `onTap` | Logo-driven, scannable, account info |
| `Badge` | `FBadge.swift` | `text`, `tone` (neutral/success/warning/danger), `soft` (Bool) | Semantic status badges, opaque or soft fill |
| `Amount` | `FAmount.swift` | `value` (paise), `format` (auto/always/compact), `tone` (neutral/debit/credit) | Colorized amount with monospace font |
| `Card` | `FDSCard.swift` | `content`, `padded`, `hoverable` | Glass or opaque card; optional tap target |
| `Glass` | `FDSGlassSurface.swift` | `content`, `material` (thin/standard/strong) | Native glass container with elevation |

---

## Integration Pattern

**Views consume the public typealiases, never FDS internals.**

```swift
import FinanceUI

struct MyView: View {
    var body: some View {
        VStack {
            // Use typealiases
            Text("Amount").font(.bodyLarge())  // AppTypography extension
            Amount(value: 150000, tone: .credit)

            FinanceButton("Save", action: { ... })

            Card {
                TransactionRow(
                    merchant: "Starbucks",
                    amount: "−₹450",
                    isDebit: true,
                    onTap: { ... }
                )
            }
        }
        .padding(AppSpacing.lg)  // Use tokens for spacing
    }
}
```

**Do NOT:**
```swift
import FinanceUI

struct BadView: View {
    var body: some View {
        FDSLiquidButton(...)  // Direct FDS reach
        FDSTransactionRow(...) // Bypasses typealias layer
    }
}
```

---

## Accessibility

### Contrast Ratios (dark mode, `AppColors.base` background)

| Text Level | Color | Value | Contrast Ratio | WCAG Level |
|------------|-------|-------|---|---|
| **Primary** | `DesignTokens.Text.primary` | #F1F3F6 on #0A0C11 | 14.8:1 | AAA |
| **Secondary** | `DesignTokens.Text.secondary` | #BDC2CC on #0A0C11 | 9.1:1 | AAA |
| **Tertiary** | `DesignTokens.Text.tertiary` | #858A94 on #0A0C11 | 4.6:1 | AA |
| **Quaternary** | `DesignTokens.Text.quaternary` | #555A64 on #0A0C11 | 2.4:1 | Decorative only |

Semantic colors (green, red, etc.) meet AA or better when used on glass or opaque backgrounds. Use `.glassSurface()` or opaque tints for sufficient contrast.

### Semantic Colors

- **Credit (green):** #30D158 — use for inflows, positive states
- **Debit (red):** #FF453A — use for outflows, negative states
- **Danger (red):** #FF453A — use for destructive actions, alerts
- **Warning (orange):** #FF9F0A — use for cautions, notifications
- **Info (blue):** #0A84FF — use for informational content

All semantic colors have soft variants (20% opacity) for backgrounds.

---

## Design Decisions

### Why Glass Materials + Wallpaper-Driven

FinanceOS uses native `NSVisualEffectView` (via SwiftUI `.Material`) for glass surfaces. This provides:
- Wallpaper-driven color (glass picks up color from desktop wallpaper underneath)
- Blur + saturation (40–60px blur, 180–190% saturation) controlled by the system compositor
- Consistent with macOS Tahoe design language
- Accessibility: high contrast against dark wallpapers

We do NOT use flat colors for primary surfaces — glass is the default.

### Dark Mode Only

FinanceOS is dark-mode-only. No light mode variants exist. This decision:
- Reduces token surface area
- Improves night usability for finance apps
- Aligns with Apple's latest macOS design direction

If light mode is needed in the future, color definitions should be migrated to `AppColors.lightMode.*` branch and applied via `@Environment(\.colorScheme)`.

### Typography: View Extensions > Static Tokens

Use `Text("...").bodyLarge()` (View extension) instead of `Text("...").font(AppTypography.bodyLarge)`.

Rationale:
- Cleaner call sites
- Future-proof: if token values change, view extensions adapt automatically
- Matches SwiftUI ergonomics (like `.bold()`, `.italic()`)

---

## Future Expansion

### Pending Design Tokens

1. **AppTypography.netHeroAmount** (48pt semibold) — added in Phase 5
2. **AppTypography.maskedAccount** (10pt monospaced) — added in Phase 5
3. Density modes via `@Environment(\.density)` — defined in `DesignTokens.Density` but not yet wired

### Planned Components

- Date picker (glass panel variant)
- Currency formatter (localized + symbol handling)
- Chart containers (with glass background)
- Analytics panels (with transaction breakdown)

---

## Migration Path (for existing callers)

If you have existing Views using `AppColors.*` or hardcoded color literals:

1. Replace hardcoded literals with `AppColors.*` or `DesignTokens.Semantic.*`
2. Replace font sizes with `AppTypography` View extensions (`.bodyLarge()`, `.captionSmall()`)
3. Replace shadow definitions with `AppShadows.*` or `.glassSurface()`
4. Use `AppSpacing.*` for padding/spacing (optional, but recommended)

No breaking changes — all tokens map to their original visual appearance.

---

## Files Reference

| Category | File | Purpose |
|----------|------|---------|
| **Tokens** | `Design/DesignTokens.swift` | Semantic colors, typography variants, elevation/density |
| **Colors** | `FinanceCore/AppColors.swift` | Canonical color definitions |
| **Typography** | `FinanceCore/AppTypography.swift` | Font scale + View extensions |
| **Typography Extensions** | `FinanceCore/AppTypography+Extensions.swift` | Specialized View extensions (netHeroAmount, maskedAccount) |
| **Spacing** | `FinanceCore/AppSpacing.swift` | 8pt grid tokens |
| **Radius** | `FinanceCore/AppRadius.swift` | Corner radius scale |
| **Shadows** | `FinanceCore/AppShadows.swift` | Elevation tiers |
| **Animation** | `FinanceCore/AppAnimation.swift` | Motion timing curves |
| **Materials** | `Materials/FDSMaterial.swift` | Glass elevation hierarchy |
| **Modifiers** | `Modifiers/` | `.glassSurface()`, `.glassStyle()`, etc. |
| **Components** | `Components/` | 40+ FDS-prefixed components |
| **Primitives** | `Primitives/` | FAmount, FBadge, FLabel |

---

## Questions?

See CLAUDE.md or file an issue on GitHub. Design system is maintained alongside app development and evolves with feature needs.
