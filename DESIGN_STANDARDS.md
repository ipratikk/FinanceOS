# FinanceOS Design Standards

## Purpose

This document defines the UI/UX design standards for the FinanceOS module.

The goal is to ensure:

* visual consistency
* predictable layouts
* scalable component architecture
* accessible interfaces
* reusable design patterns
* platform-native behavior
* maintainable SwiftUI implementation

These standards apply to:

* iOS
* iPadOS
* macOS

---

# Core Principles

## 1. Token-Driven Design

ALL visual values MUST come from design tokens.

NEVER hardcode:

* colors
* spacing
* padding
* typography
* corner radius
* shadows
* opacity
* animation timings
* borders
* gradients

BAD:

```swift
.padding(16)
.foregroundColor(.white)
.cornerRadius(12)
```

GOOD:

```swift
.padding(.spacing.md)
.foregroundStyle(.text.primary)
.cornerRadius(.radius.lg)
```

All styling values MUST originate from the reusable component library tokens.

---

# 2. Component-First Architecture

UI should be composed ONLY using reusable components.

Views should NOT directly implement:

* styling
* spacing rules
* typography decisions
* elevation
* shadows
* colors

All styling should flow through:

* tokens
* semantic styles
* reusable components

---

# 3. Semantic Styling

Use semantic tokens instead of raw appearance values.

BAD:

```swift
Color.white
```

GOOD:

```swift
ColorToken.textPrimary
```

BAD:

```swift
.padding(24)
```

GOOD:

```swift
.padding(.spacing.lg)
```

---

# 4. Dark Mode First

FinanceOS is dark-mode-first.

Every component must:

* support high contrast
* maintain readability
* avoid low-opacity text
* preserve visual hierarchy
* support accessibility modes

---

# 5. Native Apple Platform Feel

The UI should feel:

* native
* premium
* performant
* spatially balanced

Inspired by:

* Apple Wallet
* Linear
* Arc Browser
* Raycast
* Copilot Money

Avoid:

* web-admin styling
* bootstrap layouts
* crypto/neon aesthetics
* excessive gradients
* noisy visuals

---

# Design Tokens

All tokens must live inside the reusable component library.

Example:

```swift
enum DesignTokens {
    enum Spacing {}
    enum Radius {}
    enum Typography {}
    enum Colors {}
    enum Shadows {}
    enum Motion {}
}
```

---

# Color Tokens

## Backgrounds

| Token                             | Usage              |
| --------------------------------- | ------------------ |
| `ColorToken.background.primary`   | App background     |
| `ColorToken.background.secondary` | Secondary surfaces |
| `ColorToken.background.tertiary`  | Elevated surfaces  |
| `ColorToken.background.overlay`   | Overlays/sheets    |

---

## Text

| Token                       | Usage                   |
| --------------------------- | ----------------------- |
| `ColorToken.text.primary`   | Main text               |
| `ColorToken.text.secondary` | Secondary labels        |
| `ColorToken.text.tertiary`  | Metadata                |
| `ColorToken.text.inverse`   | Light-on-dark inversion |

---

## Semantic

| Token                         | Usage                |
| ----------------------------- | -------------------- |
| `ColorToken.semantic.success` | Positive values      |
| `ColorToken.semantic.warning` | Warnings             |
| `ColorToken.semantic.error`   | Errors               |
| `ColorToken.semantic.info`    | Informational states |

---

## Borders

| Token                       | Usage               |
| --------------------------- | ------------------- |
| `ColorToken.border.subtle`  | Card borders        |
| `ColorToken.border.default` | Interactive borders |
| `ColorToken.border.focused` | Focus state         |

---

# Spacing System

Use an 8pt-based spacing scale.

| Token          | Value |
| -------------- | ----- |
| `.spacing.xs`  | 4     |
| `.spacing.sm`  | 8     |
| `.spacing.md`  | 16    |
| `.spacing.lg`  | 24    |
| `.spacing.xl`  | 32    |
| `.spacing.xxl` | 48    |

Rules:

* never use arbitrary spacing
* spacing must follow hierarchy
* consistent grouping is mandatory

---

# Radius Tokens

| Token          | Usage          |
| -------------- | -------------- |
| `.radius.sm`   | Chips          |
| `.radius.md`   | Inputs/buttons |
| `.radius.lg`   | Cards          |
| `.radius.xl`   | Panels         |
| `.radius.full` | Pills/circular |

---

# Typography Standards

Typography must use semantic styles.

Never use arbitrary font sizes.

BAD:

```swift
.font(.system(size: 17))
```

GOOD:

```swift
.typography(.body)
```

---

# Typography Tokens

| Token                  | Usage            |
| ---------------------- | ---------------- |
| `.typography.hero`     | Dashboard hero   |
| `.typography.title`    | Section titles   |
| `.typography.headline` | Card titles      |
| `.typography.body`     | Standard content |
| `.typography.caption`  | Metadata         |
| `.typography.mono`     | Diagnostics/logs |

---

# Elevation Standards

Use subtle layered depth.

Avoid:

* harsh shadows
* glowing borders
* excessive blur

Use semantic elevation tokens:

| Token                | Usage           |
| -------------------- | --------------- |
| `.elevation.none`    | Flat surfaces   |
| `.elevation.sm`      | Inputs          |
| `.elevation.md`      | Cards           |
| `.elevation.lg`      | Floating panels |
| `.elevation.overlay` | Modals          |

---

# Motion Standards

Animations should:

* feel physical
* feel native
* be subtle
* reinforce hierarchy

Avoid:

* flashy transitions
* unnecessary movement

All animation timings must come from tokens.

| Token            | Usage                |
| ---------------- | -------------------- |
| `.motion.fast`   | Hover                |
| `.motion.normal` | Standard transitions |
| `.motion.slow`   | Large layout changes |

---

# Layout Standards

## Section Structure

Every screen should follow:

```text
Page
    Header
    Filters/Search
    Primary Content
    Supporting Panels
    Footer Actions
```

---

# Grouping Rules

Visually related content must:

* share spacing rhythm
* share surface hierarchy
* share alignment

Avoid:

* random spacing
* inconsistent grouping
* floating unrelated controls

---

# Card Standards

Cards must:

* use semantic surface tokens
* use consistent padding
* use consistent corner radius
* use semantic elevation
* support hover states on macOS

Cards should NEVER:

* define their own spacing rules
* hardcode colors
* define custom shadows

---

# Component Standards

## Every Component MUST:

* use tokens exclusively
* support dark mode
* support accessibility
* support Dynamic Type where applicable
* support hover states on macOS
* support reduced motion
* expose semantic APIs
* avoid direct styling overrides

---

# Charts & Analytics

Charts must:

* maintain readability
* use semantic color tokens
* avoid visual clutter
* support responsive layouts
* support loading states

Chart containers must:

* use reusable wrappers
* use standard padding
* support empty states

---

# Filtering & Search

All list-heavy screens must support:

* search
* filtering
* sorting
* contextual grouping

Filtering controls must:

* use reusable filter components
* follow spacing standards
* support keyboard navigation on macOS

---

# Empty States

Every module must support:

* loading
* empty
* error
* partial-data
* disconnected states

Empty states should:

* guide the user
* provide actions
* preserve layout balance

---

# Accessibility Standards

All UI must:

* support VoiceOver
* support Dynamic Type
* maintain contrast ratios
* support keyboard navigation
* support reduced motion

Never rely on:

* color alone
* tiny touch targets
* low-opacity text

---

# Platform Standards

## iPhone

* compact layouts
* bottom navigation
* gesture-first interaction

---

## iPad

* adaptive grids
* split layouts
* floating side panels

---

## macOS

* NavigationSplitView
* hover interactions
* keyboard shortcuts
* inspector sidebars
* resizable layouts

---

# Anti-Patterns

DO NOT:

* hardcode values
* duplicate styles
* inline spacing constants
* inline typography
* create screen-specific colors
* create one-off card styles
* create inconsistent shadows
* use arbitrary corner radius
* use random opacity values

---

# Enforcement Rules

All PRs/UI changes must:

* use tokens
* use reusable components
* follow spacing hierarchy
* follow typography standards
* support dark mode
* support accessibility
* avoid hardcoded styling

If a new visual pattern appears more than once:

* extract it into a reusable component
* define semantic tokens if necessary

---

# Final Goal

FinanceOS should feel like:

* a premium Apple-native financial operating system
* visually cohesive
* scalable
* elegant
* highly maintainable

The reusable component library and token system are the single source of truth for all UI decisions.
