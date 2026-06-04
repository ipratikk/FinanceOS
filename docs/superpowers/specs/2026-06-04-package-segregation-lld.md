# FinanceOS Package Segregation — LLD

**Author:** Pratik Goel  
**Date:** 2026-06-04  
**Status:** Approved  
**Type:** Low-Level Design  
**Related:** [PRD](2026-06-04-package-segregation-prd.md) · [HLD](2026-06-04-package-segregation-hld.md)

---

## Table of Contents

1. [Phase 1 — Eliminate UI Contamination + Adaptive Token System](#1-phase-1--eliminate-ui-contamination--adaptive-token-system)
   - 1.1 Move Design Tokens → FinanceUI
   - 1.2 Extract Bank.tintColor → FinanceUI Extension
   - 1.3 Move TargetCreationState → FinanceOSMac
   - 1.4 Move EnvironmentKey → FinanceOSMac
   - 1.5 Remove FinanceTesting from FinanceIntelligence Production Target
   - 1.6 Audit SwiftCSV in FinanceCore
   - 1.7 Adaptive Token System — Colors (Light/Dark)
   - 1.8 Adaptive Token System — Screen Scaling
   - 1.9 Verification Checklist
2. [Phase 2 — Create FinanceCLI Package](#2-phase-2--create-financecli-package)
   - 2.1 Package Structure
   - 2.2 Package.swift
   - 2.3 Command Design
   - 2.4 AppContainer Headless Initialization
   - 2.5 Verification Checklist
3. [Phase 3 — FinanceIntelligence API Boundary + Persistence Consolidation](#3-phase-3--financeintelligence-api-boundary--persistence-consolidation)
   - 3.1 Request/Response API Design
   - 3.2 Persistence — Enforce Single DatabaseQueue
   - 3.3 Migrate DB Migrations to AppMigration
   - 3.4 FinanceOSMac Consumer Updates
   - 3.5 Verification Checklist
4. [Appendix A — Adaptive Token System Full Implementation](#4-appendix-a--adaptive-token-system-full-implementation)
   - A.1 FDSBreakpoint
   - A.2 FDSScale + EnvironmentKey
   - A.3 FDSScaleModifier
   - A.4 AppTypography.Style Enum
   - A.5 FDSFontModifier
   - A.6 AppSpacing Adaptive Accessors
   - A.7 AppColors Full Light/Dark Implementation
   - A.8 New File Summary

---

## 1. Phase 1 — Eliminate UI Contamination + Adaptive Token System

**Goal:** Zero `import SwiftUI` in `FinanceCore` or `FinanceIntelligence`. No UI-state types in `FinanceCore`. No `FinanceTesting` in production targets. Design tokens enhanced with light/dark mode + screen-adaptive scaling on arrival in FinanceUI.

**Risk:** Low–Medium. File moves are low risk (build fails immediately on broken consumers). Token enhancement requires incremental callsite migration but old static tokens are kept as non-breaking aliases.

---

### 1.1 Move Design Tokens → FinanceUI

**Files to move** from `Packages/FinanceCore/Sources/FinanceCore/Design/` to `Packages/FinanceUI/Sources/FinanceUI/Design/`:

```
AppColors.swift
AppColorsExtensions.swift
AppTypography.swift
AppTypography+Extensions.swift
AppShadows.swift
AppAnimation.swift
AppSpacing.swift
AppRadius.swift
```

**Simultaneously enhance** each file per §1.7 (colors) and §1.8 (scaling) and Appendix A.

**Package.swift changes:**

`FinanceCore/Package.swift` — remove if SwiftUI no longer referenced anywhere in FinanceCore sources after the move (verify with grep):
```swift
// Remove SwiftUI from FinanceCore target if zero remaining imports
// FinanceCore has no implicit SwiftUI dep — GRDB and FinanceParsers do not require it
```

`FinanceUI/Package.swift` — no change; SwiftUI is implicit in the framework and FinanceUI already depends on FinanceCore.

**Consumer impact:** `FinanceOSMac` files that use `AppColors`, `AppTypography`, etc. via `import FinanceCore` must add `import FinanceUI`. Since FinanceOSMac already imports FinanceUI, this is an `import` statement addition only — no new Package.swift dependency.

```swift
// Before (in FinanceOSMac files):
import FinanceCore
// ... uses AppColors.base

// After:
import FinanceCore
import FinanceUI
// ... uses AppColors.base (same name, same API)
```

---

### 1.2 Extract Bank.tintColor → FinanceUI Extension

`Banks.tintColor: Color` is a display concern using SwiftUI's `Color` type. It does not belong in the domain model.

**Step 1:** Remove from `FinanceCore/Sources/FinanceCore/Models/Bank.swift`:
```swift
// Remove this property from the Banks enum:
public var tintColor: Color {
    switch self { ... }
}
// Remove: import SwiftUI
```

**Step 2:** Create `FinanceUI/Sources/FinanceUI/Extensions/Banks+SwiftUI.swift`:
```swift
import SwiftUI
import FinanceCore

public extension Banks {
    var tintColor: Color {
        switch self {
        case .hdfc:   return Color(red: 0.0,   green: 0.298, blue: 0.592)
        case .icici:  return Color(red: 0.969, green: 0.58,  blue: 0.0)
        case .amex:   return Color(red: 0.0,   green: 0.471, blue: 0.753)
        case .scapia: return Color(red: 1.0,   green: 0.42,  blue: 0.21)
        }
    }
}
```

**Consumer impact:** Zero — `FinanceOSMac` already imports `FinanceUI`. `bank.tintColor` continues to resolve.

---

### 1.3 Move TargetCreationState → FinanceOSMac

`TargetCreationState` is documented as "transient UI state accumulated during the 'add ledger' flow. Lives in a ViewModel." It is used only by `ImportViewModel` in FinanceOSMac.

**Step 1:** Delete `FinanceCore/Sources/FinanceCore/Models/TargetCreationState.swift`.

**Step 2:** Create `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/TargetCreationState.swift`:
```swift
import FinanceParsers
import Foundation

struct TargetCreationState: Identifiable, Equatable {
    // Same content as before, but access modifier changed from `public` to internal
    // (app-internal, no longer exported from a package)
    let id = UUID()
    var customName: String = ""
    var nickname: String = ""
    var first4: String = ""
    var last4: String = ""
    var encryptedCardNumber: String = ""
    var cardholderName: String = ""
    var selectedBank: Banks?
    var isCard: Bool = false
    var accountType: String = "savings"
    var cardType: CardNetwork = .other
    var cardProductId: String = ""
    var linkedLedgerId: UUID?

    init() {}

    mutating func initializeFromStatement(_ statement: ParsedStatement) {
        last4 = isCard ? (statement.cardLast4 ?? "") : (statement.accountLast4 ?? "")
        encryptedCardNumber = isCard ? (statement.metadata?.fullAccountNumber ?? "") : ""
        cardholderName = statement.metadata?.customerName ?? ""
        if isCard {
            cardType = CardNetwork(rawValue: statement.metadata?.cardType ?? "") ?? .other
        } else {
            accountType = (statement.metadata?.accountType ?? "savings").lowercased()
        }
        let displayName = statement.accountName.isEmpty ? statement.bankName : statement.accountName
        customName = displayName
    }
}
```

**Step 3:** Add `import FinanceParsers` to `Apps/FinanceOSMac/FinanceOSMac.xcodeproj` target's linked frameworks (FinanceParsers is already a transitive dep via FinanceCore — verify it's directly linkable).

**Audit:** `grep -r "TargetCreationState" Apps/FinanceOSMac/` — ensure all usages are in FinanceOSMac only (expected: ImportViewModel, ImportViewModelTargetCreation).

---

### 1.4 Move EnvironmentKey → FinanceOSMac

`FinanceIntelligence/Sources/FinanceIntelligence/EnvironmentKey.swift` defines a SwiftUI EnvironmentValues extension. This is app wiring, not intelligence logic.

**Step 1:** Delete `FinanceIntelligence/Sources/FinanceIntelligence/EnvironmentKey.swift`.

**Step 2:** Create `Apps/FinanceOSMac/FinanceOSMac/Services/IntelligenceEnvironmentKey.swift`:
```swift
import SwiftUI
import FinanceIntelligence

extension EnvironmentValues {
    @Entry var transactionIntelligence: (any TransactionIntelligenceService)?
}
```

**Consumer impact:** `FinanceOSMacApp.swift` uses `.environment(\.transactionIntelligence, ...)` — no change needed. Views using `@Environment(\.transactionIntelligence)` continue to compile — the key is still defined, just in the app target.

---

### 1.5 Remove FinanceTesting from FinanceIntelligence Production Target

Pre-audit confirmed: zero `import FinanceTesting` in `FinanceIntelligence` production sources. This is a Package.swift-only fix.

**`FinanceIntelligence/Package.swift` change:**
```swift
// Before (incorrect):
.target(
    name: "FinanceIntelligence",
    dependencies: [
        "FinanceCore",
        "FinanceTesting",    // ← remove this line
        .product(name: "GRDB", package: "GRDB.swift"),
        .product(name: "Transformers", package: "swift-transformers"),
        .product(name: "ZIPFoundation", package: "ZIPFoundation")
    ],
    resources: [.process("Resources/")]
),

// After (correct):
.target(
    name: "FinanceIntelligence",
    dependencies: [
        "FinanceCore",
        .product(name: "GRDB", package: "GRDB.swift"),
        .product(name: "Transformers", package: "swift-transformers"),
        .product(name: "ZIPFoundation", package: "ZIPFoundation")
    ],
    resources: [.process("Resources/")]
),

// FinanceTesting remains in the test target:
.testTarget(
    name: "FinanceIntelligenceTests",
    dependencies: [
        "FinanceIntelligence",
        "FinanceCore",
        "FinanceTesting",    // ← correct location
        .product(name: "GRDB", package: "GRDB.swift")
    ],
    resources: [.process("Resources")]
)
```

---

### 1.6 Audit SwiftCSV in FinanceCore

Pre-audit confirms: zero `import SwiftCSV` in `FinanceCore` production sources. SwiftCSV is used only by `FinanceParsers`.

**`FinanceCore/Package.swift` change:**
```swift
// Remove from dependencies array:
.package(url: "https://github.com/swiftcsv/SwiftCSV", from: "0.10.0"),

// Remove from FinanceCore target dependencies:
.product(name: "SwiftCSV", package: "SwiftCSV"),

// Remove from FinanceCoreTests target dependencies:
.product(name: "SwiftCSV", package: "SwiftCSV"),
```

---

### 1.7 Adaptive Token System — Colors (Light/Dark)

See Appendix A.7 for the full `AppColors` implementation. Summary of strategy:

| Token group | Change |
|-------------|--------|
| `surface`, `surface2`, `surface3` | No change — already use adaptive `NSColor` |
| `Fill.*`, `Glass.*`, `Border.*` | `Color.white.opacity(x)` → `Color.primary.opacity(x)` |
| `base`, `Text.*` | NSColor appearance-based initializer with explicit dark/light RGB |
| Accent colors | No change — brand colors are fixed across modes |
| Shadows | No change for Phase 1 — `Color.black.opacity(x)` is standard macOS |
| Legacy flat tokens | Remapped to new adaptive equivalents (same names, adaptive values) |

**Helper** (private, in AppColors namespace):
```swift
#if canImport(AppKit)
import AppKit
private extension AppColors {
    static func adaptive(
        dark: (r: CGFloat, g: CGFloat, b: CGFloat),
        light: (r: CGFloat, g: CGFloat, b: CGFloat)
    ) -> Color {
        Color(NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let rgb = isDark ? dark : light
            return NSColor(calibratedRed: rgb.r, green: rgb.g, blue: rgb.b, alpha: 1)
        })
    }
}
#elseif canImport(UIKit)
import UIKit
private extension AppColors {
    static func adaptive(
        dark: (r: CGFloat, g: CGFloat, b: CGFloat),
        light: (r: CGFloat, g: CGFloat, b: CGFloat)
    ) -> Color {
        Color(UIColor { traits in
            let rgb = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: 1)
        })
    }
}
#endif
```

---

### 1.8 Adaptive Token System — Screen Scaling

See Appendix A for full implementation of `FDSBreakpoint`, `FDSScale`, `FDSScaleModifier`, `AppTypography.Style`, and `.fdsFont()`.

**Integration — apply at app root** (`FinanceOSMacApp.swift`):
```swift
WindowGroup {
    ContentView()
        .fdsAdaptive()      // ← single call wires entire scaling system
        .environment(\.transactionIntelligence, intelligenceService)
        .environment(\.categorizationScheduler, categorizationScheduler)
        .preferredColorScheme(.dark)
        // ...
}
```

**Callsite migration pattern** (incremental — no big-bang required):
```swift
// Old (still compiles — base scale alias):
Text("Balance").font(AppTypography.displayLarge)

// New (screen-adaptive):
Text("Balance").fdsFont(.displayLarge)
```

---

### 1.9 Verification Checklist

```bash
# 1. Zero SwiftUI imports in non-UI packages
grep -r "import SwiftUI" Packages/FinanceCore/Sources/ --include="*.swift"
# Expected: no output

grep -r "import SwiftUI" Packages/FinanceIntelligence/Sources/ --include="*.swift"
# Expected: no output

# 2. FinanceTesting not in production sources
grep -r "import FinanceTesting" Packages/FinanceIntelligence/Sources/FinanceIntelligence/ --include="*.swift"
# Expected: no output

# 3. SwiftCSV removed from FinanceCore
grep "SwiftCSV" Packages/FinanceCore/Package.swift
# Expected: no output

# 4. fdsAdaptive applied at root
grep -r "fdsAdaptive" Apps/FinanceOSMac/ --include="*.swift"
# Expected: one hit in FinanceOSMacApp.swift

# 5. Full build passes
make parser-build
xcodebuild -workspace FinanceOS.xcworkspace -scheme FinanceOSMac build

# 6. Visual QA: Toggle macOS Appearance in System Settings → verify light mode
# 7. Visual QA: Connect external display or use Display > Resolution → verify type scales
```

---

## 2. Phase 2 — Create FinanceCLI Package

**Goal:** New Swift Package providing a single `FinanceCLI` executable that runs the full data pipeline headlessly: parse → import → categorize. Enables batch processing, automation, and testing without the app.

**Risk:** Medium. New package — no existing code breaks. Key risk: `AppContainer` / `DatabaseManager` headless initialization path.

---

### 2.1 Package Structure

```
Packages/
  FinanceCLI/
    Package.swift
    Sources/
      FinanceCLI/
        Commands/
          ParseCommand.swift
          ImportCommand.swift
          AnalyzeCommand.swift
          PipelineCommand.swift
        Support/
          CLIProgressReporter.swift
          CLIOutputFormatter.swift
        main.swift
```

---

### 2.2 Package.swift

```swift
// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "FinanceCLI",
    platforms: [
        .macOS("26.0")
    ],
    products: [
        .executable(name: "FinanceCLI", targets: ["FinanceCLI"])
    ],
    dependencies: [
        .package(path: "../FinanceCore"),
        .package(path: "../FinanceParsers"),
        .package(path: "../FinanceIntelligence"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0")
    ],
    targets: [
        .executableTarget(
            name: "FinanceCLI",
            dependencies: [
                "FinanceCore",
                "FinanceParsers",
                "FinanceIntelligence",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        )
    ]
)
```

---

### 2.3 Command Design

**Command interface:**
```
FinanceCLI <subcommand> [options]

Subcommands:
  parse      Parse a statement file, print normalized transactions as JSON
  import     Parse + persist to the FinanceOS SQLite database
  analyze    Run intelligence categorization on existing DB transactions
  pipeline   Full end-to-end: parse → import → analyze

Global options:
  --db-path  Path to SQLite database (default: ~/Library/Application Support/FinanceOS/finance.db)
  --format   Output format: json | human (default: human)
  --verbose  Enable verbose logging
```

**main.swift:**
```swift
import ArgumentParser

@main
struct FinanceCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "FinanceCLI",
        abstract: "FinanceOS headless pipeline — parse, import, and analyze statements",
        subcommands: [
            ParseCommand.self,
            ImportCommand.self,
            AnalyzeCommand.self,
            PipelineCommand.self
        ]
    )
}
```

**ParseCommand:**
```swift
import ArgumentParser
import FinanceParsers
import Foundation

struct ParseCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "parse",
        abstract: "Parse a statement file and print normalized transactions"
    )

    @Argument(help: "Path to the statement file (CSV or XLSX)")
    var filePath: String

    @Option(name: .long, help: "Bank identifier (hdfc, icici, amex, scapia)")
    var bank: String?

    @Flag(name: .long, help: "Print as JSON")
    var json: Bool = false

    func run() async throws {
        let url = URL(fileURLWithPath: filePath)
        let registry = StatementParserRegistry.default
        let bankEnum = bank.flatMap(Banks.init(rawValue:))
        let statement = try registry.parse(url: url, bank: bankEnum)

        if json {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(statement)
            print(String(data: data, encoding: .utf8) ?? "")
        } else {
            print("Parsed \(statement.transactions.count) transactions from \(statement.bankName)")
            for tx in statement.transactions {
                print("  \(tx.date)  \(tx.narration)  \(tx.amount)")
            }
        }
    }
}
```

**ImportCommand:**
```swift
import ArgumentParser
import FinanceCore
import FinanceParsers
import Foundation

struct ImportCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "import",
        abstract: "Parse and import a statement into the FinanceOS database"
    )

    @Argument(help: "Path(s) to statement files")
    var filePaths: [String]

    @Option(name: .long, help: "Override database path")
    var dbPath: String?

    func run() async throws {
        if let dbPath {
            DatabaseManager.configure(url: URL(fileURLWithPath: dbPath))
        }
        let container = AppContainer.shared
        for path in filePaths {
            let url = URL(fileURLWithPath: path)
            let result = try await container.transactionImportPipeline.import(from: url)
            CLIProgressReporter.report(
                "[\(url.lastPathComponent)] imported: \(result.imported), duplicates: \(result.duplicates)"
            )
        }
    }
}
```

**PipelineCommand:**
```swift
import ArgumentParser
import FinanceCore
import FinanceIntelligence
import Foundation

struct PipelineCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pipeline",
        abstract: "Full pipeline: parse → import → analyze"
    )

    @Argument(help: "Path(s) to statement files")
    var filePaths: [String]

    @Option(name: .long, help: "Override database path")
    var dbPath: String?

    @Flag(name: .long, help: "Skip categorization step")
    var skipAnalysis: Bool = false

    func run() async throws {
        if let dbPath {
            DatabaseManager.configure(url: URL(fileURLWithPath: dbPath))
        }
        let container = AppContainer.shared

        for path in filePaths {
            let url = URL(fileURLWithPath: path)

            // Import
            let importResult = try await container.transactionImportPipeline.import(from: url)
            CLIProgressReporter.report(
                "[\(url.lastPathComponent)] imported \(importResult.imported), skipped \(importResult.duplicates)"
            )

            guard !skipAnalysis, !importResult.importedTransactionIDs.isEmpty else { continue }

            // Analyze
            let config = try IntelligenceServiceConfiguration(
                databaseQueue: DatabaseManager.shared.dbQueue
            )
            let service = await TransactionIntelligenceServiceImpl(configuration: config)
            try await service.categorize(transactionIDs: importResult.importedTransactionIDs)
            CLIProgressReporter.report(
                "[\(url.lastPathComponent)] categorized \(importResult.importedTransactionIDs.count) transactions"
            )
        }
    }
}
```

**CLIProgressReporter:**
```swift
import Foundation

enum CLIProgressReporter {
    static func report(_ message: String) {
        fputs("✓ \(message)\n", stdout)
    }

    static func error(_ message: String) {
        fputs("✗ \(message)\n", stderr)
    }
}
```

---

### 2.4 AppContainer Headless Initialization

`AppContainer` uses `@MainActor` and `DatabaseManager.shared`. Both are valid in a CLI context with Swift structured concurrency — the main actor runs on the main thread, which exists in CLI executables.

**Potential issue:** `DatabaseManager` may resolve its SQLite path using `FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)`, which returns a path relative to the running application bundle. In CLI context (no app bundle), this may resolve to `~/Library/Application Support/FinanceCLI/` instead of `~/Library/Application Support/FinanceOS/`.

**Fix — add `DatabaseManager.configure(url:)` static method:**
```swift
// FinanceCore/Sources/FinanceCore/Database/DatabaseManager.swift
public final class DatabaseManager {
    private static var overridePath: URL?

    /// Call before accessing `shared` to redirect to a custom database path.
    /// Primary use: headless CLI tools.
    public static func configure(url: URL) {
        overridePath = url
    }

    public static let shared = DatabaseManager()

    private init() {
        let path = DatabaseManager.overridePath ?? DatabaseManager.defaultPath
        // ... existing init
    }

    private static var defaultPath: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("FinanceOS/finance.db")
    }
}
```

---

### 2.5 Verification Checklist

```bash
# Build
cd Packages/FinanceCLI && swift build

# Parse smoke test
.build/debug/FinanceCLI parse /path/to/hdfc-statement.csv --bank hdfc
.build/debug/FinanceCLI parse /path/to/hdfc-statement.csv --bank hdfc --json

# Import smoke test
.build/debug/FinanceCLI import /path/to/hdfc-statement.csv

# Full pipeline smoke test
.build/debug/FinanceCLI pipeline /path/to/hdfc-statement.csv
.build/debug/FinanceCLI pipeline /path/to/*.csv --skip-analysis

# Custom DB path
.build/debug/FinanceCLI import /path/to/statement.csv --db-path /tmp/test.db

# Verify no SwiftUI in CLI sources
grep -r "import SwiftUI" Sources/ --include="*.swift"
# Expected: no output
```

---

## 3. Phase 3 — FinanceIntelligence API Boundary + Persistence Consolidation

**Goal:** `FinanceIntelligence` exposes a typed request/response API. Internal models are not part of the public contract. All database access routes through a single injected `DatabaseQueue` from `DatabaseManager`. Intelligence DB migrations owned by `AppMigration` in FinanceCore.

**Risk:** High. Touches ~20 FinanceIntelligence files and all consumer call sites. Use `@available(*, deprecated)` shims during migration.

---

### 3.1 Request/Response API Design

**New file:** `FinanceIntelligence/Sources/FinanceIntelligence/API/IntelligenceRequest.swift`

```swift
import Foundation

public enum IntelligenceRequest: Sendable {
    case categorize(CategorizeRequest)
    case analyzeSpending(SpendingAnalysisRequest)
    case detectRecurring(RecurringDetectionRequest)
    case detectSalary(SalaryDetectionRequest)
    case analyzeCashflow(CashflowRequest)
    case resolveEntities(EntityResolutionRequest)
    case generateInsight(InsightRequest)
}

public struct CategorizeRequest: Sendable {
    public let transactionIDs: [UUID]
    public let forceReprocess: Bool
    public init(transactionIDs: [UUID], forceReprocess: Bool = false) {
        self.transactionIDs = transactionIDs
        self.forceReprocess = forceReprocess
    }
}

public struct SpendingAnalysisRequest: Sendable {
    public let dateRange: DateInterval
    public let ledgerIDs: [UUID]?
    public init(dateRange: DateInterval, ledgerIDs: [UUID]? = nil) {
        self.dateRange = dateRange
        self.ledgerIDs = ledgerIDs
    }
}

public struct RecurringDetectionRequest: Sendable {
    public let transactionIDs: [UUID]?
    public let minimumOccurrences: Int
    public init(transactionIDs: [UUID]? = nil, minimumOccurrences: Int = 2) {
        self.transactionIDs = transactionIDs
        self.minimumOccurrences = minimumOccurrences
    }
}

public struct SalaryDetectionRequest: Sendable {
    public let ledgerIDs: [UUID]?
    public init(ledgerIDs: [UUID]? = nil) { self.ledgerIDs = ledgerIDs }
}

public struct CashflowRequest: Sendable {
    public let dateRange: DateInterval
    public init(dateRange: DateInterval) { self.dateRange = dateRange }
}

public struct EntityResolutionRequest: Sendable {
    public let transactionIDs: [UUID]?
    public init(transactionIDs: [UUID]? = nil) { self.transactionIDs = transactionIDs }
}

public struct InsightRequest: Sendable {
    public let context: InsightContext
    public enum InsightContext: Sendable {
        case spending(dateRange: DateInterval)
        case merchant(name: String)
        case category(name: String)
    }
    public init(context: InsightContext) { self.context = context }
}
```

**New file:** `FinanceIntelligence/Sources/FinanceIntelligence/API/IntelligenceResponse.swift`

```swift
import Foundation
import FinanceCore

public enum IntelligenceResponse: Sendable {
    case categorize(CategorizeResponse)
    case analyzeSpending(SpendingAnalysisResponse)
    case detectRecurring(RecurringDetectionResponse)
    case detectSalary(SalaryDetectionResponse)
    case analyzeCashflow(CashflowResponse)
    case resolveEntities(EntityResolutionResponse)
    case generateInsight(InsightResponse)
}

public struct CategorizeResponse: Sendable {
    public let processed: Int
    public let succeeded: Int
    public let failed: Int
    public let results: [UUID: CategoryPrediction]
}

public struct SpendingAnalysisResponse: Sendable {
    public let totalSpend: Decimal
    public let byCategory: [String: Decimal]
    public let topMerchants: [MerchantSummary]
    public let insights: [TransactionInsight]
}

public struct MerchantSummary: Sendable {
    public let name: String
    public let totalSpend: Decimal
    public let transactionCount: Int
}

public struct RecurringDetectionResponse: Sendable {
    public let patterns: [RecurringPattern]
}

public struct SalaryDetectionResponse: Sendable {
    public let detected: Bool
    public let estimatedMonthlySalary: Decimal?
    public let confidence: Double
}

public struct CashflowResponse: Sendable {
    public let netCashflow: Decimal
    public let totalInflow: Decimal
    public let totalOutflow: Decimal
    public let monthlyBreakdown: [Date: CashflowPeriod]
}

public struct CashflowPeriod: Sendable {
    public let inflow: Decimal
    public let outflow: Decimal
}

public struct EntityResolutionResponse: Sendable {
    public let resolvedPersons: [Person]
    public let resolvedMerchants: [MerchantCandidate]
}

public struct InsightResponse: Sendable {
    public let narrative: String
    public let dataPoints: [String: String]
}
```

**Updated protocol** (`TransactionIntelligenceService.swift`):

```swift
public protocol TransactionIntelligenceService: AnyObject, Sendable {

    // MARK: - Primary API (use these)

    func process(_ request: IntelligenceRequest) async throws -> IntelligenceResponse
    func categorize(_ request: CategorizeRequest) async throws -> CategorizeResponse
    func analyzeSpending(_ request: SpendingAnalysisRequest) async throws -> SpendingAnalysisResponse
    func detectRecurring(_ request: RecurringDetectionRequest) async throws -> RecurringDetectionResponse
    func detectSalary(_ request: SalaryDetectionRequest) async throws -> SalaryDetectionResponse
    func analyzeCashflow(_ request: CashflowRequest) async throws -> CashflowResponse
    func resolveEntities(_ request: EntityResolutionRequest) async throws -> EntityResolutionResponse
    func generateInsight(_ request: InsightRequest) async throws -> InsightResponse
}
```

**Deprecation shims** for old call sites (add to `TransactionIntelligenceServiceImpl`):
```swift
// TransactionIntelligenceServiceImpl+Deprecated.swift
extension TransactionIntelligenceServiceImpl {
    @available(*, deprecated, renamed: "categorize(_:)")
    public func categorize(transactionIDs: [UUID]) async throws {
        _ = try await categorize(CategorizeRequest(transactionIDs: transactionIDs))
    }
}
```

---

### 3.2 Persistence — Enforce Single DatabaseQueue

**Invariant:** `FinanceIntelligence` never calls `DatabaseQueue(path:)` or `DatabasePool(path:)` directly. All database access uses the `DatabaseQueue` injected via `IntelligenceServiceConfiguration(databaseQueue:)`.

**Audit steps:**
```bash
# Find any direct DatabaseQueue/Pool construction in FinanceIntelligence:
grep -rn "DatabaseQueue(" Packages/FinanceIntelligence/Sources/FinanceIntelligence/ --include="*.swift"
grep -rn "DatabasePool(" Packages/FinanceIntelligence/Sources/FinanceIntelligence/ --include="*.swift"
# Expected: zero hits (all db access via the injected queue)
```

**Add enforcing comment to `IntelligenceServiceConfiguration`:**
```swift
// IntelligenceServiceConfiguration.swift
public struct IntelligenceServiceConfiguration {
    // MARK: - Architecture Invariant
    // Never construct a DatabaseQueue here. Always receive from FinanceCore's DatabaseManager.
    // This ensures a single SQLite file is shared between core and intelligence layers.
    public let databaseQueue: DatabaseQueue
    // ...
}
```

**Ensure all initializations pass the shared queue:**
```swift
// FinanceOSMacApp.swift — already correct, verify:
let config = try IntelligenceServiceConfiguration(
    databaseQueue: DatabaseManager.shared.dbQueue  // ← single source of truth
)

// FinanceCLI PipelineCommand — same pattern:
let config = try IntelligenceServiceConfiguration(
    databaseQueue: DatabaseManager.shared.dbQueue
)
```

---

### 3.3 Migrate DB Migrations to AppMigration

Intelligence DB tables are currently registered inside FinanceIntelligence's initialization path. This creates a race condition if the service is initialized before the tables exist (possible in CLI context).

**Tables to migrate** (SQL ownership moves from FinanceIntelligence init → `AppMigration.swift`):
- `feedback_events`
- `graph_nodes`
- `graph_edges`
- `inference_events`
- `intelligence_persons`
- `intelligence_person_aliases`
- `recurring_patterns`
- `relationships`

**Action:**

1. Extract `CREATE TABLE` SQL from FinanceIntelligence initialization into `FinanceCore/Sources/FinanceCore/Database/AppMigration.swift` as a named migration.

2. Remove table creation from FinanceIntelligence init — tables exist before the service initializes.

3. GRDB model structs (`GRDBGraphNode`, `GRDBFeedbackEvent`, etc.) stay in FinanceIntelligence — only the migration SQL moves.

```swift
// AppMigration.swift (addition)
migrator.registerMigration("v4_intelligence_tables") { db in
    try db.create(table: "graph_nodes", ifNotExists: true) { t in
        t.column("id", .text).primaryKey()
        t.column("kind", .text).notNull()
        t.column("label", .text).notNull()
        t.column("metadata", .text)
    }
    // ... remaining table definitions
}
```

---

### 3.4 FinanceOSMac Consumer Updates

All FinanceOSMac call sites that use old intelligence methods (pre-typed-API) must be migrated. During the migration window, deprecated shims keep them compiling.

**Migration pattern:**
```swift
// Before:
try await intelligenceService?.categorize(transactionIDs: ids)

// After:
let response = try await intelligenceService?.categorize(
    CategorizeRequest(transactionIDs: ids)
)
```

**Files expected to need updates** (audit with `grep -r "intelligenceService\." Apps/FinanceOSMac/`):
- `CategorizationScheduler.swift`
- `DashboardViewModel.swift`
- `ImportViewModel.swift`
- `AnalyticsViewModel.swift`
- Other ViewModels that call intelligence methods

---

### 3.5 Verification Checklist

```bash
# No DatabaseQueue construction in FinanceIntelligence sources
grep -rn "DatabaseQueue(" Packages/FinanceIntelligence/Sources/FinanceIntelligence/ --include="*.swift"
grep -rn "DatabasePool(" Packages/FinanceIntelligence/Sources/FinanceIntelligence/ --include="*.swift"
# Expected: zero hits

# FinanceIntelligence builds
swift build --package-path Packages/FinanceIntelligence

# FinanceOSMac builds with updated API calls
xcodebuild -workspace FinanceOS.xcworkspace -scheme FinanceOSMac build

# Intelligence tests pass
swift test --package-path Packages/FinanceIntelligence

# FinanceCLI pipeline works end-to-end
.build/debug/FinanceCLI pipeline /path/to/statement.csv

# No deprecated shim usages remain (post-migration):
grep -r "@available.*deprecated" Packages/FinanceIntelligence/Sources/ --include="*.swift"
# Expected: zero hits after all consumers migrated
```

---

## 4. Appendix A — Adaptive Token System Full Implementation

### A.1 FDSBreakpoint

**File:** `FinanceUI/Sources/FinanceUI/Environment/FDSBreakpoint.swift`

```swift
import Foundation

public enum FDSBreakpoint: Equatable, Sendable {
    /// < 1200pt — small window or constrained display
    case compact
    /// 1200–1800pt — MacBook 13"/14" (base scale = 1.0)
    case regular
    /// 1800–2400pt — MacBook Pro 16", iMac 24"
    case large
    /// > 2400pt — iMac 27", Studio Display, Pro Display XDR
    case xlarge

    public init(screenWidth: CGFloat) {
        switch screenWidth {
        case ..<1200:     self = .compact
        case 1200..<1800: self = .regular
        case 1800..<2400: self = .large
        default:          self = .xlarge
        }
    }

    public var typographyScale: CGFloat {
        switch self {
        case .compact: return 0.875
        case .regular: return 1.0
        case .large:   return 1.1
        case .xlarge:  return 1.2
        }
    }

    public var spacingScale: CGFloat {
        switch self {
        case .compact: return 0.875
        case .regular: return 1.0
        case .large:   return 1.125
        case .xlarge:  return 1.25
        }
    }
}
```

**Reference:**

| Device | Logical Width | Breakpoint | Type × | Spacing × |
|--------|-------------|------------|--------|-----------|
| MacBook Air 13" M2 | ~1280pt | regular | 1.0 | 1.0 |
| MacBook Pro 14" | ~1512pt | regular | 1.0 | 1.0 |
| MacBook Pro 16" | ~1728pt | regular | 1.0 | 1.0 |
| iMac 24" | ~2240pt | large | 1.1 | 1.125 |
| iMac 27" / Studio Display | ~2560pt | xlarge | 1.2 | 1.25 |
| Pro Display XDR | ~3008pt | xlarge | 1.2 | 1.25 |

---

### A.2 FDSScale + EnvironmentKey

**File:** `FinanceUI/Sources/FinanceUI/Environment/FDSScale.swift`

```swift
import SwiftUI

public struct FDSScale: Equatable, Sendable {
    public let typography: CGFloat
    public let spacing: CGFloat
    public let breakpoint: FDSBreakpoint

    public static let `default` = FDSScale(
        typography: 1.0,
        spacing: 1.0,
        breakpoint: .regular
    )
}

private struct FDSScaleKey: EnvironmentKey {
    static let defaultValue = FDSScale.default
}

public extension EnvironmentValues {
    var fdsScale: FDSScale {
        get { self[FDSScaleKey.self] }
        set { self[FDSScaleKey.self] = newValue }
    }
}
```

---

### A.3 FDSScaleModifier

**File:** `FinanceUI/Sources/FinanceUI/Environment/FDSScaleModifier.swift`

```swift
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

struct FDSScaleModifier: ViewModifier {
    @State private var scale: FDSScale = .default

    func body(content: Content) -> some View {
        content
            .environment(\.fdsScale, scale)
            .onAppear { scale = resolvedScale() }
#if os(macOS)
            .onReceive(
                NotificationCenter.default.publisher(
                    for: NSApplication.didChangeScreenParametersNotification
                )
            ) { _ in scale = resolvedScale() }
#endif
    }

    private func resolvedScale() -> FDSScale {
#if os(macOS)
        let width = NSScreen.main?.frame.width ?? 1280
#else
        let width: CGFloat = 1280  // iOS: scaling via Dynamic Type, not screen width
#endif
        let breakpoint = FDSBreakpoint(screenWidth: width)
        return FDSScale(
            typography: breakpoint.typographyScale,
            spacing: breakpoint.spacingScale,
            breakpoint: breakpoint
        )
    }
}

public extension View {
    func fdsAdaptive() -> some View {
        modifier(FDSScaleModifier())
    }
}
```

---

### A.4 AppTypography.Style Enum

Add to `FinanceUI/Sources/FinanceUI/Design/AppTypography.swift` (full replacement shown for the enum + static token aliases only; `Dynamic` enum is unchanged):

```swift
import SwiftUI

public enum AppTypography {

    // MARK: - Style (use with .fdsFont() for adaptive scaling)

    public enum Style: CaseIterable {
        case displayLarge, displaySmall
        case headingXL, headingXLLight, headingLg, headingLgLight
        case headingMd, headingMdRegular, headingSm, headlineSmLight
        case subheadline
        case screenTitle, titleSm
        case bodyLg, bodyMd, bodyMdLight, bodyMdSemibold
        case bodySm, bodySmMedium, bodySmSemibold
        case labelSemibold, labelMedium, labelRegular, labelSmall
        case captionLg, captionLgSemibold, captionLgMedium
        case captionSm, captionSmSemibold, captionSmMedium
        case amountLarge, amountMd, amountSm, amountXs
        case iconMd, iconSm, iconXs
        case netHeroAmount, maskedAccount

        public var baseSize: CGFloat {
            switch self {
            case .displayLarge:       return 36
            case .displaySmall:       return 28
            case .headingXL:          return 28
            case .headingXLLight:     return 28
            case .headingLg:          return 24
            case .headingLgLight:     return 24
            case .headingMd:          return 20
            case .headingMdRegular:   return 20
            case .headingSm:          return 17
            case .headlineSmLight:    return 17
            case .subheadline:        return 16
            case .screenTitle:        return 32
            case .titleSm:            return 20
            case .bodyLg:             return 16
            case .bodyMd:             return 15
            case .bodyMdLight:        return 15
            case .bodyMdSemibold:     return 15
            case .bodySm:             return 14
            case .bodySmMedium:       return 14
            case .bodySmSemibold:     return 14
            case .labelSemibold:      return 14
            case .labelMedium:        return 14
            case .labelRegular:       return 14
            case .labelSmall:         return 13
            case .captionLg:          return 13
            case .captionLgSemibold:  return 13
            case .captionLgMedium:    return 13
            case .captionSm:          return 12
            case .captionSmSemibold:  return 12
            case .captionSmMedium:    return 12
            case .amountLarge:        return 22
            case .amountMd:           return 18
            case .amountSm:           return 15
            case .amountXs:           return 13
            case .iconMd:             return 17
            case .iconSm:             return 15
            case .iconXs:             return 13
            case .netHeroAmount:      return 52
            case .maskedAccount:      return 12
            }
        }

        public var weight: Font.Weight {
            switch self {
            case .headingXLLight, .headingLgLight, .headlineSmLight, .bodyMdLight:
                return .light
            case .displayLarge, .headingXL, .headingLg, .screenTitle,
                 .headingMd, .titleSm, .subheadline,
                 .bodyMdSemibold, .bodySmSemibold,
                 .labelSemibold, .captionLgSemibold, .captionSmSemibold,
                 .amountLarge, .amountMd, .netHeroAmount:
                return .semibold
            case .headingSm:
                return .semibold
            case .bodySmMedium, .labelMedium, .captionLgMedium, .captionSmMedium:
                return .medium
            default:
                return .regular
            }
        }

        public var design: Font.Design {
            switch self {
            case .amountLarge, .amountMd, .amountSm, .amountXs, .maskedAccount:
                return .monospaced
            default:
                return .default
            }
        }

        public func font(scale: CGFloat = 1.0) -> Font {
            Font.system(size: baseSize * scale, weight: weight, design: design)
        }
    }

    // MARK: - Static Tokens (backward-compatible, base scale — migrate to .fdsFont())

    public static let displayLarge      = Style.displayLarge.font()
    public static let displaySmall      = Style.displaySmall.font()
    public static let headingXL         = Style.headingXL.font()
    public static let headingXLLight    = Style.headingXLLight.font()
    public static let headingLg         = Style.headingLg.font()
    public static let headingLgLight    = Style.headingLgLight.font()
    public static let headingMd         = Style.headingMd.font()
    public static let headingMdRegular  = Style.headingMdRegular.font()
    public static let headingSm         = Style.headingSm.font()
    public static let headlineSmLight   = Style.headlineSmLight.font()
    public static let subheadline       = Style.subheadline.font()
    public static let screenTitle       = Style.screenTitle.font()
    public static let titleSm           = Style.titleSm.font()
    public static let bodyLg            = Style.bodyLg.font()
    public static let bodyMd            = Style.bodyMd.font()
    public static let bodyMdLight       = Style.bodyMdLight.font()
    public static let bodyMdSemibold    = Style.bodyMdSemibold.font()
    public static let bodySm            = Style.bodySm.font()
    public static let bodySmMedium      = Style.bodySmMedium.font()
    public static let bodySmSemibold    = Style.bodySmSemibold.font()
    public static let labelSemibold     = Style.labelSemibold.font()
    public static let labelMedium       = Style.labelMedium.font()
    public static let labelRegular      = Style.labelRegular.font()
    public static let labelSmall        = Style.labelSmall.font()
    public static let captionLg         = Style.captionLg.font()
    public static let captionLgSemibold = Style.captionLgSemibold.font()
    public static let captionLgMedium   = Style.captionLgMedium.font()
    public static let captionSm         = Style.captionSm.font()
    public static let captionSmSemibold = Style.captionSmSemibold.font()
    public static let captionSmMedium   = Style.captionSmMedium.font()
    public static let amountLarge       = Style.amountLarge.font()
    public static let amountMd          = Style.amountMd.font()
    public static let amountSm          = Style.amountSm.font()
    public static let amountXs          = Style.amountXs.font()
    public static let iconMd            = Style.iconMd.font()
    public static let iconSm            = Style.iconSm.font()
    public static let iconXs            = Style.iconXs.font()
    public static let netHeroAmount     = Style.netHeroAmount.font()
    public static let maskedAccount     = Style.maskedAccount.font()

    // Aliases (kept for source compatibility)
    public static let headlineSm        = headingSm
    public static let label             = labelSmall

    // MARK: - Dynamic Type (system-driven, unchanged)

    public enum Dynamic {
        public static let display: Font    = .largeTitle.bold()
        public static let title: Font      = .title.bold()
        public static let title2: Font     = .title2.weight(.semibold)
        public static let title3: Font     = .title3.weight(.semibold)
        public static let headline: Font   = .headline
        public static let body: Font       = .body
        public static let callout: Font    = .callout
        public static let subheadline: Font = .subheadline
        public static let footnote: Font   = .footnote
        public static let caption: Font    = .caption
        public static let caption2: Font   = .caption2
    }
}
```

---

### A.5 FDSFontModifier

**File:** `FinanceUI/Sources/FinanceUI/Modifiers/FDSFontModifier.swift`

```swift
import SwiftUI

struct FDSFontModifier: ViewModifier {
    let style: AppTypography.Style
    @Environment(\.fdsScale) private var fdsScale

    func body(content: Content) -> some View {
        content.font(style.font(scale: fdsScale.typography))
    }
}

public extension View {
    func fdsFont(_ style: AppTypography.Style) -> some View {
        modifier(FDSFontModifier(style: style))
    }
}
```

---

### A.6 AppSpacing Adaptive Accessors

**File:** `FinanceUI/Sources/FinanceUI/Modifiers/FDSSpacingModifier.swift`

```swift
import SwiftUI

struct FDSPaddingModifier: ViewModifier {
    let edges: Edge.Set
    let base: CGFloat
    @Environment(\.fdsScale) private var fdsScale

    func body(content: Content) -> some View {
        content.padding(edges, base * fdsScale.spacing)
    }
}

public extension View {
    func fdsPadding(_ edges: Edge.Set = .all, _ base: CGFloat) -> some View {
        modifier(FDSPaddingModifier(edges: edges, base: base))
    }
}

public extension AppSpacing {
    static func scaled(_ base: CGFloat, by factor: CGFloat) -> CGFloat {
        base * factor
    }
}
```

---

### A.7 AppColors Full Light/Dark Implementation

Key tokens that change. Full file replaces existing `AppColors.swift` in FinanceUI.

```swift
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

public enum AppColors {

    // MARK: - Adaptive Helper

    private static func adaptive(
        dark: (r: CGFloat, g: CGFloat, b: CGFloat),
        light: (r: CGFloat, g: CGFloat, b: CGFloat)
    ) -> Color {
#if canImport(AppKit)
        Color(NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let rgb = isDark ? dark : light
            return NSColor(calibratedRed: rgb.r, green: rgb.g, blue: rgb.b, alpha: 1)
        })
#elseif canImport(UIKit)
        Color(UIColor { traits in
            let rgb = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: 1)
        })
#else
        Color(red: dark.r, green: dark.g, blue: dark.b)
#endif
    }

    // MARK: - Backgrounds

    /// Dark: #0f0f12 · Light: #F5F5F7
    public static let base = adaptive(
        dark:  (r: 0.060, g: 0.060, b: 0.070),
        light: (r: 0.961, g: 0.961, b: 0.969)
    )

    /// System-adaptive surfaces (unchanged — NSColor already handles light/dark)
    public static let surface  = Color(NSColor.controlBackgroundColor)
    public static let surface2 = Color(NSColor.windowBackgroundColor)
    public static let surface3 = Color(NSColor.textBackgroundColor)

    // MARK: - Fill Hierarchy (adaptive via Color.primary)

    public enum Fill {
        public static let primary    = Color.primary.opacity(0.05)
        public static let secondary  = Color.primary.opacity(0.08)
        public static let tertiary   = Color.primary.opacity(0.11)
        public static let quaternary = Color.primary.opacity(0.15)
    }

    // MARK: - Glass Surfaces (adaptive via Color.primary)

    public enum Glass {
        public static let thinTint  = Color.primary.opacity(0.04)
        public static let surface   = Color.primary.opacity(0.06)
        public static let midTint   = Color.primary.opacity(0.08)
        public static let thickTint = Color.primary.opacity(0.10)
        public static let highlight = Color.primary.opacity(0.12)
        /// Dark chrome — intentionally dark in both modes (sidebar chrome)
        public static let chrome    = Color(red: 20/255, green: 22/255, blue: 30/255).opacity(0.65)
        public static let inputWell = AppColors.base.opacity(0.25)

        public static var gleamBorder: LinearGradient {
            LinearGradient(
                colors: [
                    Color.primary.opacity(0.16),
                    Color.primary.opacity(0.06),
                    .clear,
                    AppColors.base.opacity(0.20)
                ],
                startPoint: .top, endPoint: .bottom
            )
        }
    }

    // MARK: - Border Hierarchy (adaptive via Color.primary)

    public enum Border {
        public static let subtle = Color.primary.opacity(0.06)
        public static let strong = Color.primary.opacity(0.10)
        public static let input  = Color.primary.opacity(0.25)
        public static let focus  = AppColors.accentGreen.opacity(0.70)
    }

    // MARK: - Text Hierarchy (adaptive)

    public enum Text {
        /// Dark: #F1F3F6  Light: #1C1C1E
        public static let primary = adaptive(
            dark:  (r: 0.945, g: 0.953, b: 0.965),
            light: (r: 0.110, g: 0.110, b: 0.118)
        )
        /// Dark: #BDC2CC  Light: #3C3C43
        public static let secondary = adaptive(
            dark:  (r: 0.741, g: 0.761, b: 0.800),
            light: (r: 0.235, g: 0.235, b: 0.263)
        )
        /// Dark: #858A94  Light: #636366
        public static let tertiary = adaptive(
            dark:  (r: 0.518, g: 0.541, b: 0.580),
            light: (r: 0.388, g: 0.388, b: 0.400)
        )
        /// Dark: #8F94A0  Light: #6C6C70
        public static let tertiaryElevated = adaptive(
            dark:  (r: 0.560, g: 0.580, b: 0.620),
            light: (r: 0.424, g: 0.424, b: 0.439)
        )
        /// Dark: #636874  Light: #8E8E93 — decorative only
        public static let quaternary = adaptive(
            dark:  (r: 0.390, g: 0.410, b: 0.450),
            light: (r: 0.557, g: 0.557, b: 0.576)
        )
        /// Dark: #52525B  Light: #AEAEB2
        public static let disabled = adaptive(
            dark:  (r: 0.322, g: 0.322, b: 0.361),
            light: (r: 0.682, g: 0.682, b: 0.698)
        )
    }

    // MARK: - Brand Accents (fixed — same in light and dark)

    public static let accentGreen  = Color(red: 0.188, green: 0.827, blue: 0.345)
    public static let accentOrange = Color(red: 1.000, green: 0.620, blue: 0.040)
    public static let accentBlue   = Color(red: 0.039, green: 0.518, blue: 1.000)
    public static let accentPurple = Color(red: 0.749, green: 0.345, blue: 0.949)
    public static let accentMuted  = Color(red: 0.557, green: 0.557, blue: 0.576)

    // Aliases
    public static let accentGold  = accentOrange
    public static let accentSlate = accentBlue
    public static let accentIce   = accentBlue

    // MARK: - Semantic Colors

    public static let accent   = accentGreen
    public static let success  = accentGreen
    public static let danger   = Color(red: 1.000, green: 0.231, blue: 0.188)
    public static let info     = accentBlue
    public static let warning  = Color(red: 1.000, green: 0.584, blue: 0.000)
    public static let credit   = success
    public static let debit    = danger
    public static let purple   = accentPurple

    // MARK: - Legacy Flat Tokens (remapped to adaptive — source compatible)

    public static let textPrimary   = Text.primary
    public static let textSecondary = Text.secondary
    public static let textTertiary  = Text.tertiary
    public static let textDisabled  = Text.disabled
    public static let border        = Border.subtle
    public static let borderAccent  = Border.strong
    public static let glass         = Glass.thinTint
    public static let clear         = Color.clear

    // MARK: - System Palette (macOS system colors — inherently adaptive)

    public enum System {
        public static let red    = Color(red: 1.00, green: 0.27, blue: 0.23)
        public static let orange = Color(red: 1.00, green: 0.62, blue: 0.04)
        public static let yellow = Color(red: 1.00, green: 0.84, blue: 0.04)
        public static let green  = Color(red: 0.19, green: 0.82, blue: 0.35)
        public static let mint   = Color(red: 0.40, green: 0.83, blue: 0.81)
        public static let teal   = Color(red: 0.25, green: 0.78, blue: 0.88)
        public static let cyan   = Color(red: 0.39, green: 0.82, blue: 1.00)
        public static let blue   = Color(red: 0.04, green: 0.52, blue: 1.00)
        public static let indigo = Color(red: 0.37, green: 0.36, blue: 0.90)
        public static let purple = Color(red: 0.75, green: 0.35, blue: 0.95)
        public static let pink   = Color(red: 1.00, green: 0.22, blue: 0.37)
        public static let gray   = Color(red: 0.60, green: 0.60, blue: 0.62)
    }

    // MARK: - Opacity Scale

    public enum Opacity {
        public static let low:    Double = 0.20
        public static let medium: Double = 0.30
        public static let muted:  Double = 0.40
        public static let high:   Double = 0.50
        public static let strong: Double = 0.80
    }
}
```

---

### A.8 New File Summary

All new files in `FinanceUI/Sources/FinanceUI/`:

```
Environment/
  FDSBreakpoint.swift              — breakpoint enum + scale factors
  FDSScale.swift                   — environment value struct + EnvironmentKey
  FDSScaleModifier.swift           — .fdsAdaptive() root modifier

Modifiers/
  FDSFontModifier.swift            — .fdsFont(.style) view modifier (new)
  FDSSpacingModifier.swift         — .fdsPadding(_:_:) modifier (new)

Design/ (moved from FinanceCore + enhanced)
  AppColors.swift                  — full light/dark adaptive implementation
  AppColorsExtensions.swift        — moved, updated to use adaptive helpers
  AppTypography.swift              — + Style enum + scaled font() func
  AppTypography+Extensions.swift   — moved, unchanged
  AppShadows.swift                 — moved, no structural changes (Phase 1)
  AppAnimation.swift               — moved, no changes needed
  AppSpacing.swift                 — moved + AppSpacing.scaled(_:by:) added
  AppRadius.swift                  — moved, no changes needed

Extensions/
  Banks+SwiftUI.swift              — tintColor (extracted from FinanceCore Bank.swift)
```

Files deleted from `FinanceCore/Sources/FinanceCore/`:
```
Design/AppColors.swift
Design/AppColorsExtensions.swift
Design/AppTypography.swift
Design/AppTypography+Extensions.swift
Design/AppShadows.swift
Design/AppAnimation.swift
Design/AppSpacing.swift
Design/AppRadius.swift
Models/TargetCreationState.swift    (moved to FinanceOSMac)
```

Files deleted from `FinanceIntelligence/Sources/FinanceIntelligence/`:
```
EnvironmentKey.swift                (moved to FinanceOSMac)
```
