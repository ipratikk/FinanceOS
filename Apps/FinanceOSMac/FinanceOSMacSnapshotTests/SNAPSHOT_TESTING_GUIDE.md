# FinanceOS Snapshot Testing Guide

Comprehensive guide for implementing and maintaining snapshot tests in FinanceOS.

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Test Organization](#test-organization)
4. [Writing Snapshot Tests](#writing-snapshot-tests)
5. [Running Tests](#running-tests)
6. [Snapshot Updates](#snapshot-updates)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

---

## Overview

Snapshot testing validates UI consistency by comparing rendered views against reference images. Changes in layout, spacing, colors, or typography are caught immediately.

### Benefits

- **Regression prevention** — Catch unintended UI changes
- **Deterministic** — Same render every time (fixed dates, fonts, animations)
- **Fast** — Quick to write, quick to run
- **Visual feedback** — See exactly what changed
- **Documentation** — Snapshots document expected UI appearance
- **Accessibility** — Test dynamic type and contrast

### Dependencies

- `SnapshotTesting` (swift-snapshot-testing)
- `FinanceTesting` (custom infrastructure)
- `Swift Testing` framework

---

## Quick Start

### 1. Create a Basic Snapshot Test

```swift
import Testing
import SwiftUI
import FinanceTesting
@testable import FinanceOSMac

@Suite
struct MyViewSnapshotTests {
    @Test("My view light mode")
    func myViewLightMode() {
        let view = MyView()
            .snapshotEnvironment()
            .snapshotTheme(.light)
        
        assertSnapshot(of: view, as: .image, named: "MyView.light")
    }
}
```

### 2. Run Tests

```bash
# Run all snapshot tests
xcodebuild -scheme FinanceOSMac -testPlan SnapshotTests test

# Record new snapshots (first run only)
UPDATE_SNAPSHOTS=1 xcodebuild -scheme FinanceOSMac test

# Run specific test suite
xcodebuild -scheme FinanceOSMac -testPlan SnapshotTests -testFilter DashboardViewSnapshotTests test
```

### 3. Review Changes

Snapshot diffs are available in:
- Xcode test report (Photos app integration)
- Failed test output shows expected vs. actual
- Git diff of snapshot files

---

## Test Organization

### Directory Structure

```
FinanceOSMacSnapshotTests/
├── Screens/                      # Full-screen snapshots
│   ├── DashboardViewSnapshotTests.swift
│   ├── SidebarViewSnapshotTests.swift
│   ├── CardsViewSnapshotTests.swift
│   └── AccountsViewSnapshotTests.swift
├── Components/                   # Reusable components
│   ├── TransactionRowSnapshotTests.swift
│   ├── CardRowSnapshotTests.swift
│   └── MetricCardSnapshotTests.swift
├── Flows/                        # Multi-step flows
│   ├── ImportFlowSnapshotTests.swift
│   └── CrossFlowSnapshotTests.swift
└── SNAPSHOT_TESTING_GUIDE.md
```

### Test Naming

Use consistent naming for easy reference:

- **View tests**: `[ViewName]SnapshotTests`
- **Snapshot names**: `ViewName.variant` or `ViewName.theme.device`
  - Example: `DashboardView.light`
  - Example: `TransactionRow.debit.dark.iPhone16Pro`

---

## Writing Snapshot Tests

### Basic Pattern

```swift
@Suite
struct MyViewSnapshotTests {
    @Test("My view default")
    func myViewDefault() {
        let view = MyView()
            .snapshotEnvironment()     // Apply deterministic settings
        
        assertSnapshot(of: view, as: .image, named: "MyView")
    }
}
```

### Theme Variants

```swift
@Test("My view light and dark modes")
func myViewThemes() {
    for theme in SnapshotTheme.allCases {
        let view = MyView()
            .snapshotEnvironment()
            .snapshotTheme(theme)
        
        let name = SnapshotNaming.namedWithTheme("MyView", theme: theme)
        assertSnapshot(of: view, as: .image, named: name)
    }
}
```

### Device Variants

```swift
@Test("My view on all devices")
func myViewAllDevices() {
    for device in SnapshotDevice.iOSDevices {
        let view = MyView()
            .snapshotEnvironment()
            .frame(width: device.size.width, height: device.size.height)
        
        let name = SnapshotNaming.namedWithDevice("MyView", device: device)
        assertSnapshot(of: view, as: .image, named: name)
    }
}
```

### Preview Data

Use `FinanceTesting` preview data:

```swift
@Test("Dashboard with preview accounts")
func dashboardWithData() {
    let view = DashboardView(accounts: PreviewAccounts.all)
        .snapshotEnvironment()
    
    assertSnapshot(of: view, as: .image, named: "Dashboard.withData")
}
```

### Component Sizing

For component tests, use fixed sizes:

```swift
@Test("Button component snapshot")
func buttonComponent() {
    let view = ButtonComponent(title: "Import")
        .frame(height: 44)
        .snapshotEnvironment()
    
    assertSnapshot(of: view, as: .image, named: "Button.primary")
}
```

### Dynamic Type

Test accessibility sizes:

```swift
@Test("Large dynamic type")
func largeType() {
    let view = MyView()
        .snapshotEnvironment()
        .snapshotDynamicType(.large)
    
    assertSnapshot(of: view, as: .image, named: "MyView.largeType")
}
```

---

## Running Tests

### Xcode GUI

1. Open Test Navigator (Cmd+6)
2. Find test suite: `FinanceOSMacSnapshotTests`
3. Click play button to run
4. View results in test report

### Command Line

```bash
# Run all snapshot tests
xcodebuild \
  -workspace FinanceOS.xcworkspace \
  -scheme FinanceOSMac \
  test \
  -testPlan SnapshotTests

# Run specific test class
xcodebuild \
  -workspace FinanceOS.xcworkspace \
  -scheme FinanceOSMac \
  test \
  -testFilter DashboardViewSnapshotTests

# Run with verbose output
xcodebuild \
  -workspace FinanceOS.xcworkspace \
  -scheme FinanceOSMac \
  test \
  -testPlan SnapshotTests \
  -verbose

# Record new snapshots
UPDATE_SNAPSHOTS=1 xcodebuild \
  -workspace FinanceOS.xcworkspace \
  -scheme FinanceOSMac \
  test
```

---

## Snapshot Updates

### First Time Recording

```bash
# Record all snapshots
UPDATE_SNAPSHOTS=1 xcodebuild \
  -workspace FinanceOS.xcworkspace \
  -scheme FinanceOSMac \
  test

# Snapshots are stored in:
# FinanceOSMacSnapshotTests/__Snapshots__/ViewNameSnapshotTests
```

### Updating After Intentional Changes

When you intentionally change UI:

1. Update your code
2. Run tests — they'll fail
3. Review the diff (Xcode shows photo comparison)
4. If changes are correct:
   ```bash
   UPDATE_SNAPSHOTS=1 xcodebuild ... test
   ```
5. Verify and commit the updated snapshots

### CI Integration

In CI, snapshots should **not** be updated — they should match or fail:

```bash
# CI runs without UPDATE_SNAPSHOTS
xcodebuild -workspace FinanceOS.xcworkspace test
# Fails if any snapshot differs
```

---

## Best Practices

### 1. Use Deterministic Data

All snapshots use fixed dates (2025-05-15 09:30:00 UTC):

```swift
// ✅ Good: Uses SnapshotConfiguration.referenceDate
let view = MyView(date: SnapshotConfiguration.current.referenceDate)

// ❌ Bad: Uses current date (non-deterministic)
let view = MyView(date: Date())
```

### 2. Test Key Variants

Create snapshots for important combinations:

```swift
@Test("Complete coverage")
func completeCoverage() {
    // ✅ Good: Light/dark, small/large type, key devices
    for theme in SnapshotTheme.allCases {
        for size in [DynamicTypeSize.small, .large] {
            for device in [.iPhone16Pro, .iPadPro] {
                // snapshot
            }
        }
    }
    
    // ❌ Bad: All 32 combinations (overkill, slow)
    for device in SnapshotDevice.allCases {
        for theme in SnapshotTheme.allCases {
            for size in DynamicTypeSize.allCases {
                // snapshot
            }
        }
    }
}
```

### 3. Keep Snapshots Focused

One concept per snapshot:

```swift
// ✅ Good: Single responsibility
func transactionRowDebit() { ... }
func transactionRowCredit() { ... }

// ❌ Bad: Too much in one snapshot
func transactionRowAllVariants() { /* tests 10 states */ }
```

### 4. Use Meaningful Names

```swift
// ✅ Good: Clear variant
named: "CardView.dark.largeType"

// ❌ Bad: Meaningless suffix
named: "CardView_1"
```

### 5. Version Control

Commit snapshot changes with intent:

```
Commit message:
  ui: Update CardView snapshot for new spacing

  - Increased padding from 12pt to 16pt
  - Updated CardView snapshots to match new spacing
  - Verified light/dark/large-type variants
```

### 6. Mock External Data

Use preview data, not live API:

```swift
// ✅ Good: Deterministic
let view = ListView(accounts: PreviewAccounts.all)

// ❌ Bad: Non-deterministic
let view = ListView(accounts: accountRepository.fetchAll())
```

### 7. Document Complex Snapshots

```swift
@Test("Import flow review state with duplicates")
func importFlowReviewDuplicates() {
    // Testing:
    // 1. Duplicate detection highlighting
    // 2. Skip/merge options
    // 3. Transaction preview cards
    let view = ImportReviewView(
        duplicatesDetected: 3,
        transactionsToImport: 50
    )
    // ...
}
```

---

## Troubleshooting

### Snapshot Mismatch in CI

**Problem**: Test passes locally but fails in CI.

**Cause**: Different rendering environment (fonts, system version, DPI).

**Solution**:
```swift
// Use deterministic sizes and fonts
.font(.system(.body, design: .default))
.frame(width: 390)  // Explicit size, not adaptive

// Avoid:
// .frame(maxWidth: .infinity)  — varies by device
// @Environment(\.self) — includes system state
```

### Snapshot Too Large

**Problem**: Snapshot image is huge, hard to review.

**Solution**: Break into smaller components:

```swift
// ❌ Bad: Full screen (800KB)
let view = DashboardView()

// ✅ Good: Individual row (20KB)
let view = DashboardRow(account: account)
    .frame(maxWidth: 390)
```

### Flaky Snapshots

**Problem**: Snapshot sometimes matches, sometimes doesn't.

**Cause**: Async operations, animations, random values.

**Solution**:
```swift
// Ensure deterministic
let view = MyView()
    .snapshotEnvironment()  // Disables animations
    .task { }               // Wait for async setup
```

### Snapshot File Size

Store snapshots efficiently:

```bash
# Recommended format: PNG (compressed)
# Default: SnapshotTesting uses PNG

# Never commit:
# - Xcode temporary files
# - DerivedData
# - Build artifacts
```

---

## Next Steps

1. **Add snapshot tests** for each new view
2. **Review snapshots** before committing
3. **Update on intent** — Only when design changes are intentional
4. **Monitor CI** — Snapshots help prevent regressions

## Resources

- [SnapshotTesting Documentation](https://github.com/pointfreeco/swift-snapshot-testing)
- [FinanceTesting Package](../../../Packages/FinanceTesting)
- [Project Architecture](../../../ARCHITECTURE.md)
