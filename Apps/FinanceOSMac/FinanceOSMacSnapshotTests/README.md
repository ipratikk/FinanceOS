# FinanceOS Snapshot Tests

Snapshot testing for FinanceOS using [SnapshotTesting](https://github.com/pointfreeco/swift-snapshot-testing) + XCTest.

## Overview

Snapshot tests capture rendered SwiftUI views as reference images and detect regressions by comparing against new renders.

## Quick Start

### Running Tests

```bash
# Run all snapshot tests
xcodebuild -workspace FinanceOS.xcworkspace -scheme FinanceOSMac test

# Record new snapshots (first time only)
xcodebuild -workspace FinanceOS.xcworkspace -scheme FinanceOSMac test -testPlan SnapshotTests -- record=true

# Run specific test class
xcodebuild -workspace FinanceOS.xcworkspace -scheme FinanceOSMac test -testFilter DashboardViewSnapshotTests
```

### Writing a Snapshot Test

```swift
import XCTest
import SwiftUI
import SnapshotTesting
import FinanceTesting

final class MyViewSnapshotTests: XCTestCase {
    let record = false
    
    func test_myView_initial() {
        let view = MyView()
        verifySnapshots(view, device: .iPhone16Pro, record: record)
    }
}
```

The `verifySnapshots` helper automatically:
- Renders light and dark mode variants
- Uses device-specific layout (iPhone 16 Pro, iPhone SE, iPad Pro, macOS)
- Stores reference images in `__Snapshots__/` directory

### Updating Snapshots

When you intentionally change UI:

```swift
let record = true  // Set to true
let view = UpdatedView()
verifySnapshots(view, device: .iPhone16Pro, record: record)
```

Then set back to `false` and verify the diff looks correct.

## File Structure

```
FinanceOSMacSnapshotTests/
├── Helpers/
│   └── XCTestCase+Snapshot.swift      # Test helpers
├── Screens/
│   ├── DashboardViewSnapshotTests.swift
│   ├── SidebarViewSnapshotTests.swift
│   ├── CardsViewSnapshotTests.swift
│   └── AccountsViewSnapshotTests.swift
├── Components/
│   ├── TransactionRowSnapshotTests.swift
│   ├── CardRowSnapshotTests.swift
│   └── MetricCardSnapshotTests.swift
├── Flows/
│   ├── ImportFlowSnapshotTests.swift
│   └── CrossFlowSnapshotTests.swift
├── __Snapshots__/                     # Reference images (auto-generated)
│   ├── DashboardViewSnapshotTests/
│   ├── SidebarViewSnapshotTests/
│   └── ...
└── README.md
```

## Devices Supported

- **iPhone 16 Pro** (393×852, notch) - Default
- **iPhone SE** (375×667)
- **iPad Pro** (1024×1366)
- **macOS** (1200×800)

## API Reference

### Verify Single Device (Light + Dark)

```swift
verifySnapshots(
    view,
    device: .iPhone16Pro,
    record: false
)
```

### Verify Component with Fixed Size

```swift
verifyComponentSnapshots(
    buttonView,
    size: CGSize(width: 390, height: 44),
    record: false
)
```

### Verify Across All Devices

```swift
verifySnapshotsAcrossDevices(
    view,
    devices: .iOSDevices,  // or .allCases
    record: false
)
```

## Preview Data

Use `FinanceTesting` package for deterministic test data:

```swift
import FinanceTesting

let ledgers = PreviewLedgers.all      // Checking, Savings, Credit Card
let transactions = PreviewTransactions.samples
```

## Configuration

All snapshots use deterministic settings:
- **Locale**: en_US
- **Timezone**: UTC  
- **Reference Date**: 2025-05-18
- **Color Schemes**: Light + Dark (automatic)

## CI/CD Integration

Snapshots are CI-friendly:

1. **Record mode** (`record=true`): Only on first commit
2. **Verify mode** (`record=false`): Default, fails if snapshots don't match
3. **Review**: Snapshot diffs visible in PR workflows

```yaml
# Example GitHub Actions
- name: Snapshot Tests
  run: |
    xcodebuild test \
      -workspace FinanceOS.xcworkspace \
      -scheme FinanceOSMac \
      -testPlan SnapshotTests
```

## Troubleshooting

### Snapshot mismatch in CI

Different system rendering can cause mismatches. Ensure:
- Snapshots recorded on macOS arm64
- No dynamic content (dates, animations)
- SnapshotTesting version consistent

### Large snapshot files

Keep snapshots focused:
- One concept per snapshot
- Use component snapshots for small UI elements
- Full-screen snapshots only for complete flows

### Recording new snapshots

```swift
// Temporarily set record = true
func test_myView() {
    let view = MyView()
    verifySnapshots(view, device: .iPhone16Pro, record: true)  // ← true
}

// Run test to record
xcodebuild test -testFilter test_myView

// Set back to false
record: false
```

## Best Practices

1. **One concept per test** — Test single UI state or variant
2. **Meaningful names** — Use clear test function names
3. **Light + Dark** — Always verify both color schemes
4. **Component focus** — Small snapshots are faster
5. **Preview data** — Use stable test data, never live API
6. **Version control** — Commit snapshot diffs with intent
7. **Review carefully** — Approve diffs before merging

## Resources

- [SnapshotTesting GitHub](https://github.com/pointfreeco/swift-snapshot-testing)
- [FinanceTesting Package](../../../Packages/FinanceTesting)
- [Spendora Reference Implementation](../../Documents/Github/Spendora)
