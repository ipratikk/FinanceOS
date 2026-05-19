# FinanceOS - Modern Futuristic Design System

## 1. Design Philosophy

**Aesthetic Direction**: Cyberpunk-inspired luxury fintech UI
- Dark, immersive environment (late-night trader aesthetic)
- Neon accents cut through darkness (urgent, high-tech)
- Glassmorphism + translucent layers (depth, sophistication)
- Smooth micro-interactions (responsive, premium feel)
- Data visualization as visual hero (money-in-motion)

**Core Principle**: Information hierarchy through luminosity and layering, not clutter.

---

## 2. Color Palette

### Background Colors
| Token | Hex | RGB | Usage |
|-------|-----|-----|-------|
| `bg-midnight` | #0D0D14 | rgb(13, 13, 20) | Page background |
| `bg-surface` | #141420 | rgb(20, 20, 32) | Card/container bg |
| `bg-elevated` | #1A1A28 | rgb(26, 26, 40) | Hover state, depth |
| `bg-overlay` | #0D0D14 | rgb(13, 13, 20, 0.7) | Modal backdrop |

### Neon Accent Colors
| Token | Hex | RGB | Usage |
|-------|-----|-----|-------|
| `accent-cyan` | #00F0FF | rgb(0, 240, 255) | Primary action, data highlight |
| `accent-blue` | #3399FF | rgb(51, 153, 255) | Secondary, charts |
| `accent-purple` | #CC33FF | rgb(204, 51, 255) | Tertiary, badges |
| `accent-pink` | #FF1B9D | rgb(255, 27, 157) | Alerts, warnings |
| `accent-lime` | #66FF00 | rgb(102, 255, 0) | Positive, gains |
| `accent-orange` | #FF6600 | rgb(255, 102, 0) | Negative, losses |

### Semantic Colors
| Token | Hex | RGB | Usage |
|-------|-----|-----|-------|
| `success` | #00D966 | rgb(0, 217, 102) | Positive states |
| `danger` | #FF3333 | rgb(255, 51, 51) | Destructive actions |
| `warning` | #FFB800 | rgb(255, 184, 0) | Caution states |
| `info` | #00B4FF | rgb(0, 180, 255) | Information |

### Neutral Colors
| Token | Hex | RGB | Usage |
|-------|-----|-----|-------|
| `text-primary` | #FFFFFF | rgb(255, 255, 255) | Primary text |
| `text-secondary` | #B3B3C4 | rgb(179, 179, 196) | Secondary text |
| `text-tertiary` | #808090 | rgb(128, 128, 144) | Disabled, muted |
| `border-subtle` | #2A2A3E | rgb(42, 42, 62, 0.3) | Subtle dividers |
| `border-strong` | #00F0FF | rgb(0, 240, 255, 0.2) | Accent borders |

---

## 3. Typography System

### Font Stack
- **Display**: `"SF Pro Display"` (macOS/iOS native) — bold, tight-tracked
- **Heading**: `"SF Pro Display"` — semibold, slightly tracked
- **Body**: `"SF Pro Text"` (macOS/iOS native) — regular, -0.5pt tracking
- **Monospace**: `"SF Mono"` (for amounts, codes) — regular

### Type Scale

| Style | Size | Weight | Line Height | Letter Spacing | Usage |
|-------|------|--------|-------------|----------------|-------|
| Display XL | 48px | Bold | 1.2 | -0.02em | Hero headlines |
| Display L | 40px | Bold | 1.2 | -0.02em | Page titles |
| Headline L | 32px | Semibold | 1.3 | -0.01em | Section headers |
| Headline M | 24px | Semibold | 1.4 | 0em | Card headers |
| Title L | 20px | Semibold | 1.4 | 0em | Subsections |
| Title M | 18px | Semibold | 1.5 | 0em | Input labels |
| Body L | 16px | Regular | 1.6 | 0em | Main content |
| Body M | 14px | Regular | 1.6 | 0em | Secondary content |
| Body S | 13px | Regular | 1.5 | 0.005em | Descriptions |
| Label M | 12px | Medium | 1.4 | 0.02em | Buttons, badges |
| Label S | 11px | Medium | 1.3 | 0.03em | Small labels |
| Caption | 10px | Regular | 1.3 | 0.02em | Hints, timestamps |
| Mono (Amounts) | 20px | Semibold | 1.2 | 0em | Currency values |

---

## 4. Spacing System

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4px | Icon spacing |
| `sm` | 8px | Tight gaps |
| `md` | 12px | Default gaps |
| `lg` | 16px | Comfortable spacing |
| `xl` | 24px | Section spacing |
| `2xl` | 32px | Major sections |
| `3xl` | 48px | Page margins |

---

## 5. Component Design Specs

### 5.1 Card (Glassmorphic)

**Base Properties:**
- Background: `bg-surface` with 60% opacity
- Border: 1px `border-strong` (cyan glow, 20% opacity)
- Corner Radius: 16px
- Shadow: `0px 20px 60px rgba(0, 240, 255, 0.1)`
- Backdrop Filter: `blur(20px)`
- Padding: 20px (lg spacing)

**States:**
- **Hover**: Opacity +10%, border opacity +10%, shadow grows
- **Active**: bg-elevated, border opacity +20%
- **Disabled**: opacity -50%, text-tertiary

**Example: Account Card**
```
┌─────────────────────────────┐
│ Account Balance       [edit] │  Title M, text-secondary
│ $24,580.50                  │  Mono, accent-cyan
│ +$1,200 (4.9%) today        │  Body S, success
└─────────────────────────────┘
```

### 5.2 Button (Neon)

**Primary Button:**
- Background: Linear gradient (accent-blue → accent-cyan)
- Text: black, Label M Bold
- Padding: 12px 24px
- Corner Radius: 12px
- Height: 48px (touch target)
- Shadow: `0px 0px 20px rgba(51, 153, 255, 0.4)`

**States:**
- **Hover**: Brightness +10%, glow expands
- **Active**: Brightness -10%, shadow darker
- **Disabled**: opacity -60%, no glow

**Secondary Button:**
- Background: transparent
- Border: 1px accent-cyan with glow
- Text: accent-cyan
- On hover: bg-elevated

### 5.3 Data Visualization Cards

**Line Chart Card**
- Height: 280px
- Grid lines: `border-subtle` (dotted)
- Plot area: 60% height, centered
- Tooltip: bg-elevated, border-strong, 200ms fade-in

**Metric Tile**
- Display current value in accent-cyan (mono)
- Show change (+/- with color) in success/danger
- Sparkline underneath (tiny line chart)
- Icon in corner (optional, monochrome)

### 5.4 Input Fields

**Text Input**
- Background: bg-elevated
- Border: 1px border-subtle
- On focus: border accent-cyan, glow 0px 0px 12px rgba(0, 240, 255, 0.2)
- Placeholder: text-tertiary
- Padding: 12px 16px
- Height: 44px (touch target)
- Corner Radius: 8px

**Label:** Title M, text-secondary, 8px above input

### 5.5 Badges & Chips

**Category Badge** (transaction type)
- Background: Semi-transparent neon color (color varies by category)
- Text: label S, bold
- Padding: 4px 12px
- Corner Radius: 4px
- Example: `[TRANSFER]` in accent-blue, `[SHOPPING]` in accent-pink

---

## 6. Animation Guidelines

### Page Transitions
- Duration: 300ms
- Easing: `cubic-bezier(0.4, 0.0, 0.2, 1)` (material-decelerate)
- Fade in + subtle scale (1.02 → 1.0)

### Micro-interactions
- Toggle/Switch: 200ms (spring: damping 0.8, stiffness 200)
- Hover states: 150ms ease-out
- Loading spinner: 1.2s linear, rotate

### Entrance Animations
- Cards: Stagger 50ms between rows, fade + slide-up (24px)
- Charts: Draw animation 1s ease-in-out (strokeDasharray)
- Numbers: Counter animation 500ms ease-out

### Gesture Feedback (iOS/macOS)
- Tap/Press: 80ms pulse scale (0.98 → 1.0)
- Swipe: Follow finger, snap to end with damping
- Long press: Haptic + 200ms scale (1.04)

---

## 7. Layout Specs

### Margins & Gutters

| Device | Margin | Gutter |
|--------|--------|--------|
| macOS (Large) | 48px | 24px |
| macOS (Medium) | 32px | 20px |
| iPad | 32px | 20px |
| iPhone | 16px | 12px |

### Safe Areas
- macOS: 48px from edge
- iOS: Standard safe area insets (notch, home indicator)

### Grid
- 12-column grid (macOS)
- 1-column grid (mobile)
- Breakpoint: 680px

---

## 8. Dark Mode Enforcement

**Always use dark theme.** No light mode variant. Neon colors are designed to pierce darkness.

Ambient light detection (if supported) should:
- Increase brightness slightly outdoors
- Maintain dark bg-midnight
- Never switch to light theme

---

## 9. Accessibility

### Contrast
- Text on dark: WCAG AAA (7:1 minimum)
- Neon on dark: Always meets AAA for body text
- Color + shape for status (don't rely on color alone)

### Touch Targets
- Minimum 44×44pt (iOS/macOS)
- Icon-only buttons: 48×48pt
- Spacing between targets: 8pt minimum

### Reduced Motion
- Respect `prefers-reduced-motion`
- Fade instead of scale/slide
- Disable particle effects

### Dark Mode APIs
- macOS: `@Environment(\.colorScheme)`
- iOS: `UITraitCollection.current.userInterfaceStyle`

---

## 10. Implementation Checklist

### SwiftUI

- [ ] Create `DesignTokens` enum with all colors, spacing, typography
- [ ] Create `DesignSystemModifiers` (card style, button style, input style)
- [ ] Build component library (Card, Button, Input, Badge, Chart wrapper)
- [ ] Create example screens showing all components
- [ ] Add animations with `.animation()` and `.transition()`
- [ ] Test on macOS (light/dark, scaling) and iOS (safe areas)
- [ ] Verify contrast with accessibility inspector
- [ ] Snapshot tests for all components

### Figma

- [ ] Create color palette page
- [ ] Typography scale demonstration
- [ ] Component library (base + states)
- [ ] Example screens (Dashboard, Accounts, Transactions, Settings)
- [ ] Animation specs (timing, easing curves)
- [ ] Prototypes linking screens with transitions

---

## 11. Design Decisions Rationale

**Why Cyberpunk + Luxury?**
- Fintech audience: young, tech-savvy, appreciates boldness
- Neon in dark = premium, confident, modern
- Glassmorphism = layered information (bank account hierarchy)
- Smooth animations = trust, precision (money management)

**Why No Light Mode?**
- Dark theme reduces eye strain (trader screens, phone at night)
- Neon + dark is a complete aesthetic (not a variation)
- Accessibility still met (WCAG AAA contrast)

**Why These Neon Colors?**
- Cyan: trust, stability (primary data)
- Blue: finance, security (secondary)
- Purple: premium, rare transactions (tertiary)
- Lime: gains, positive outcomes (semantic)
- Orange/Pink: losses, warnings (semantic)

---

## 12. Assets & Resources

### Figma File
- URL: To be shared after design approval
- Status: Design system ready for handoff

### SwiftUI Implementation
- Location: `Packages/FinanceUI/Sources/FinanceUI/Design/`
- Files:
  - `DesignTokens.swift` — Colors, spacing, typography
  - `DesignSystemModifiers.swift` — Card, button, input styles
  - `ComponentLibrary/` — Reusable components

### Icon Set
- Source: SF Symbols (macOS/iOS native)
- Style: Monochrome or accent-colored variants
- Weight: Regular, Medium (never Bold for icons)

---

## 13. Example Screen Layouts

### Dashboard (Main)
```
┌───────────────────────────────────────────────────┐
│ 🔷 PORTFOLIO OVERVIEW                     [settings]│ Header
├───────────────────────────────────────────────────┤
│ TOTAL VALUE       CHANGE TODAY                    │ Key metrics
│ $128,450          +$3,200 (2.5%)                  │
├───────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────┐  │ Chart card
│ │ 7-Day Trend                          ╱╲    │  │ (glassmorphic)
│ │                           ╱╲    ╱╲  ╱  ╲   │  │
│ │ Accounts: $128.4K        ╱  ╲__╱  ╲╱    ╲  │  │
│ └─────────────────────────────────────────────┘  │
│                                                   │
│ ┌─────────────────────┐ ┌──────────────────────┐ │ Account cards
│ │ Checking: $24,580   │ │ Savings: $78,900     │ │ (stacked grid)
│ │ +$800 today         │ │ +$2,400 today        │ │
│ └─────────────────────┘ └──────────────────────┘ │
│                                                   │
│ [Send] [Request] [Details]                       │ Action buttons
└───────────────────────────────────────────────────┘
```

### Accounts Detail
```
┌───────────────────────────────────────────────────┐
│ ← Chase Checking                          [•••]   │ Header
├───────────────────────────────────────────────────┤
│ BALANCE: $24,580.50                             │ Primary info
│ APY: 0.5% • No fees • FDIC insured              │ Meta info
├───────────────────────────────────────────────────┤
│ Recent Transactions                             │ Section
│ ┌─────────────────────────────────────────────┐ │
│ │ [SHOPPING] Whole Foods              -$48.23 │ │ Transaction
│ │ Today at 2:14 PM                            │ │
│ └─────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────┐ │
│ │ [TRANSFER] Pay to Sarah             -$200   │ │
│ │ Yesterday at 9:30 AM                        │ │
│ └─────────────────────────────────────────────┘ │
│                                                   │
│ [View All Transactions]                         │ CTA
└───────────────────────────────────────────────────┘
```

---

## Version
- **Created**: May 2026
- **Status**: Ready for implementation
- **Target**: FinanceOS v2.0 (Modern UI Redesign)
