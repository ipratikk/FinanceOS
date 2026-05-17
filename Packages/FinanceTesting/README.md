# FinanceTesting

Production-grade snapshot testing infrastructure for FinanceOS using `SnapshotTesting`.

## Overview

FinanceTesting provides:

- **Deterministic snapshot rendering** — Fixed dates, stable locales, disabled animations
- **Device-specific snapshots** — iPhone 16 Pro, iPhone SE, iPad Pro, macOS
- **Theme support** — Light and dark mode snapshots
- **Dynamic type testing** — Accessibility size snapshots
- **Preview data factories** — Pre-built accounts, transactions, cards for testing
- **Snapshot helpers** — Reusable containers and modifiers for consistent snapshots

## Quick Start

### Basic Snapshot Test

```swift
import Testing
import SwiftUI
import SnapshotTesting
import FinanceTesting

@Test
func dashboardSnapshot() {
    let view = DashboardView(viewModel: .preview)
        .snapshotEnvironment()
    
    assertSnapshot(of: view, as: .image)
}
```

### Multi-Device Snapshots

```swift
@Test
func cardSnapshot() {
    for device in SnapshotDevice.allCases {
        let view = CardView()
            .snapshotEnvironment()
        
        let name = SnapshotNaming.named("CardView", device: device)
        assertSnapshot(of: view, as: .image, named: name)
    }
}
```

### Theme Variants

```swift
@Test
func listViewThemes() {
    for theme in SnapshotTheme.allCases {
        let view = ListView()
            .snapshotTheme(theme)
            .snapshotEnvironment()
        
        let name = SnapshotNaming.namedWithTheme("ListView", theme: theme)
        assertSnapshot(of: view, as: .image, named: name)
    }
}
```

## Key Components

### SnapshotConfiguration

Global deterministic rendering settings:

```swift
let config = SnapshotConfiguration.default
// config.referenceDate = 2025-05-15 09:30:00
// config.locale = en_US
// config.timeZone = UTC
// config.animationsDisabled = true
```

### SnapshotDevice

Device configurations:

```swift
SnapshotDevice.iPhone16Pro    // 393 × 852, notch insets
SnapshotDevice.iPhoneSE        // 375 × 667
SnapshotDevice.iPadPro         // 1024 × 1366
SnapshotDevice.macOS           // 1200 × 800
```

### SnapshotNaming

Consistent naming for snapshots:

```swift
SnapshotNaming.named("CardView")                           // CardView
SnapshotNaming.namedWithTheme("CardView", theme: .dark)   // CardView.dark
SnapshotNaming.namedWithDevice("CardView", device: .iPhoneSE) // CardView.iPhoneSE
SnapshotNaming.namedForAllThemes("CardView")               // ["CardView.light", "CardView.dark"]
```

### Containers

Pre-sized containers for consistent snapshots:

```swift
// Full screen snapshot
SnapshotContainer(myView, device: .iPhone16Pro)

// Component snapshot  
ComponentSnapshotContainer(myButton, size: CGSize(width: 390, height: 100))
```

### Modifiers

```swift
view
    .snapshotEnvironment()          // Apply deterministic settings
    .snapshotTheme(.dark)            // Set color scheme
    .snapshotDynamicType(.large)     // Set accessibility size
    .snapshotSize(.expanded)         // Set width variant
```

## Preview Data

Pre-built test data:

```swift
import FinanceTesting

let account = PreviewAccounts.checking()
let transaction = PreviewTransactions.debit(
    merchant: "Whole Foods",
    amount: 50.00
)
```

## Architecture

```
FinanceTesting/
├── Sources/
│   └── FinanceTesting/
│       ├── SnapshotHelpers/
│       │   ├── SnapshotConfiguration.swift
│       │   ├── SnapshotDevice.swift
│       │   ├── SnapshotNaming.swift
│       │   ├── SnapshotContainer.swift
│       │   └── DynamicTypeSnapshot.swift
│       ├── Modifiers/
│       │   ├── DeterministicEnvironmentModifier.swift
│       │   └── ThemeSnapshotModifier.swift
│       ├── TestStores/
│       │   ├── PreviewAccounts.swift
│       │   └── PreviewTransactions.swift
│       └── FinanceTesting.swift
└── Tests/
    └── FinanceTesting/
```

## Best Practices

1. **Use deterministic data** — All snapshots use fixed dates (2025-05-15 09:30:00 UTC)
2. **Name consistently** — Use `SnapshotNaming` helpers to avoid random names
3. **Test key variants** — Light/dark mode, default/large type, key devices
4. **Keep snapshots small** — Snapshot individual components, not massive views
5. **Review on changes** — Always review snapshot diffs before approving
6. **CI-friendly** — Snapshots are deterministic and CI-safe

## Testing Checklist

When adding snapshot tests:

- [ ] Light and dark mode snapshots
- [ ] Default and accessibility type size
- [ ] Key devices (iPhone, iPad, macOS if applicable)
- [ ] Empty states
- [ ] Loading states
- [ ] Error states
- [ ] All theme variants

## Integration with Swift Testing

SnapshotTesting works seamlessly with Swift Testing framework:

```swift
import Testing

@Test
func viewSnapshot() async {
    let view = MyView()
    assertSnapshot(of: view, as: .image)
}

@Test("Snapshots across all devices")
func multiDeviceSnapshots() {
    for device in SnapshotDevice.allCases {
        // snapshot for each device
    }
}
```

## Dependencies

- `swift-snapshot-testing` — Snapshot testing library
- `FinanceCore` — Domain models and business logic
- `FinanceUI` — UI components

## CI Integration

Snapshots work with standard CI:

1. **Recording** — Run with `UPDATE_SNAPSHOTS=1` to record new snapshots
2. **Verifying** — Run normally in CI; fails if snapshots don't match
3. **Reviewing** — Snapshot diffs are reviewable in PR workflows
