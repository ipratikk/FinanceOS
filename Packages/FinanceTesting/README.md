# FinanceTesting

Test infrastructure for FinanceOS snapshot testing using `SnapshotTesting` + XCTest.

## Overview

FinanceTesting provides:

- **Deterministic test configuration** — Fixed dates, stable locales, UTC timezone
- **Device configurations** — iPhone 16 Pro, iPhone SE, iPad Pro, macOS
- **Preview data factories** — Ledgers, transactions, and other test models
- **Support for XCTest snapshot testing** — Helpers in app test target

## Quick Start

### Basic Snapshot Test

```swift
import XCTest
import SwiftUI
import SnapshotTesting
import FinanceTesting

final class DashboardViewSnapshotTests: XCTestCase {
    let record = false
    
    func test_dashboard_initial() {
        let view = DashboardView()
        verifySnapshots(view, device: .iPhone16Pro, record: record)
    }
}
```

The `verifySnapshots` helper automatically generates:
- Light mode snapshot (named `iPhone16Pro.Light`)
- Dark mode snapshot (named `iPhone16Pro.Dark`)

### Preview Data

```swift
import FinanceTesting

let ledgers = PreviewLedgers.all           // Checking, Savings, Credit Card
let debit = PreviewTransactions.debit()
let credit = PreviewTransactions.credit()
```

## Key Components

### SnapshotConfiguration

Deterministic rendering constants:

```swift
SnapshotConfiguration.referenceDate  // 2025-05-18 00:00:00 UTC
SnapshotConfiguration.locale         // en_US
SnapshotConfiguration.timeZone       // UTC
```

### SnapshotDevice

Device configurations:

```swift
SnapshotDevice.iPhone16Pro    // 393 × 852 (notch)
SnapshotDevice.iPhoneSE       // 375 × 667
SnapshotDevice.iPadPro        // 1024 × 1366
SnapshotDevice.macOS          // 1200 × 800

// Collections
SnapshotDevice.allCases       // All devices
SnapshotDevice.mobileDevices  // iPhone + iPad
SnapshotDevice.iOSDevices     // iPhone only
```

### Preview Data Factories

```swift
// Ledgers
PreviewLedgers.checking()  // Chase Checking (****1234)
PreviewLedgers.savings()   // Chase Savings (****5678)
PreviewLedgers.creditCard() // Amex Premium (****9999)
PreviewLedgers.all         // All three

// Transactions
PreviewTransactions.debit(description:, amountMinorUnits:)
PreviewTransactions.credit(description:, amountMinorUnits:)
PreviewTransactions.samples // Collection of both types
```

## Usage in Tests

See `FinanceOSMacSnapshotTests/` for complete examples.

### Single Device (Light + Dark)

```swift
func test_myView() {
    let view = MyView()
    verifySnapshots(view, device: .iPhone16Pro, record: record)
}
```

### Component with Fixed Size

```swift
func test_button() {
    let view = CustomButton(title: "Import")
    verifyComponentSnapshots(
        view,
        size: CGSize(width: 390, height: 44),
        record: record
    )
}
```

### Multiple Devices

```swift
func test_myView_allDevices() {
    let view = MyView()
    verifySnapshotsAcrossDevices(
        view,
        devices: .iOSDevices,
        record: record
    )
}
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
│       │   └── DynamicTypeSnapshot.swift
│       ├── Modifiers/
│       │   ├── DeterministicEnvironmentModifier.swift
│       │   └── ThemeSnapshotModifier.swift
│       ├── TestStores/
│       │   ├── PreviewAccounts.swift
│       │   └── PreviewTransactions.swift
│       └── FinanceTesting.swift
└── README.md
```

Test helpers (XCTestCase extensions) live in test target:
```
FinanceOSMacSnapshotTests/
└── Helpers/
    └── XCTestCase+Snapshot.swift
```

## Recording Snapshots

First time only:

```swift
// In test
let record = true  // ← Temporarily

// Run test
xcodebuild test -testFilter test_myView

// Verify snapshots in __Snapshots__/ directory
// Set record = false
```

## CI Integration

```bash
# Record (first time, usually local)
xcodebuild test ... record=true

# Verify (standard CI)
xcodebuild test ...
```

Failed snapshots will show diff images comparing expected vs actual.

## Dependencies

- `swift-snapshot-testing` — Image snapshot library
- `FinanceCore` — Domain models
- `FinanceUI` — UI components
- XCTest — In test target only

## Resources

- [SnapshotTesting GitHub](https://github.com/pointfreeco/swift-snapshot-testing)
- [FinanceOSMac Snapshot Tests](../Apps/FinanceOSMac/FinanceOSMacSnapshotTests)
- [Spendora Reference](https://github.com/Spendora/Spendora)
