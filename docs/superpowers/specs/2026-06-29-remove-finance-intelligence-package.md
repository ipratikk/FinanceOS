# Remove FinanceIntelligence Swift Package

**Date:** 2026-06-29
**Branch:** feat/calculations-fix-FINOS-92
**Status:** Approved

## Context

Intelligence moves to Python backend. The `FinanceIntelligence` Swift package (local GRDB, CoreML, MLX) is no longer needed in the iOS/macOS app. Category picker and filter UI are retained and wired to the existing `RecategorizeMutation` GQL endpoint.

---

## What Gets Deleted

### Package
- `Packages/FinanceIntelligence/` — entire directory

### App files — full delete
- `Presentation/Intelligence/IntelligenceHubView.swift`
- `Presentation/Intelligence/IntelligenceContainer.swift`
- `Presentation/Intelligence/IntelligenceExporter.swift`
- `Presentation/Intelligence/IntelligencePipelineOverlay.swift`
- `Presentation/Intelligence/FinanceAgentViewModel.swift` (and paired View if exists)
- `Presentation/Intelligence/DevHub/GraphHubView.swift`
- `Presentation/Intelligence/DevHub/GraphViewModel.swift`
- `Presentation/Intelligence/DevHub/GraphCanvasView.swift`
- `Presentation/Intelligence/DevHub/PersonsView.swift`
- `Presentation/Intelligence/DevHub/RelationshipsView.swift`
- `Presentation/Intelligence/DevHub/RecurringPatternsView.swift`
- `Services/CategorizationScheduler.swift`
- `Services/IntelligenceEnvironmentKey.swift`

### Navigation
- Remove `NavigationItem.intelligence` and `NavigationItem.financeAgent` from sidebar enum and all switch statements
- Remove `.intelligence` and `.financeAgent` cases from `DetailRouter`

---

## What Gets Moved

| From | To |
|------|----|
| `FinanceIntelligence/Domain/CategoryTaxonomy.swift` | `Packages/FinanceCore/Sources/FinanceCore/Models/CategoryTaxonomy.swift` |
| `Presentation/Intelligence/CategoryPickerView.swift` | `Presentation/Shared/Views/CategoryPickerView.swift` |
| `Presentation/Intelligence/CategoryPickerDestination.swift` | `Presentation/Shared/Views/CategoryPickerDestination.swift` |
| `Presentation/Intelligence/CategoryCorrectionViewModel.swift` | `Presentation/Shared/CategoryCorrectionViewModel.swift` |
| `Presentation/Intelligence/CategorySymbol.swift` | `Presentation/Shared/CategorySymbol.swift` |

---

## What Gets Rewired

### `CategoryTaxonomy` → FinanceCore
- Move `CategoryTaxonomy`, `TaxonomyCategory`, `TaxonomySubcategory` structs to `FinanceCore/Models/CategoryTaxonomy.swift`
- No dependency changes needed — pure Foundation types
- All consumers swap `import FinanceIntelligence` → `import FinanceCore`

### `CategoryCorrectionViewModel`
- Remove: `TransactionIntelligenceService`, `CategoryPrediction`, `previousPrediction` param
- Add: `ApolloGraphQLClient` injection
- `save()` calls `RecategorizeMutation(transactionId:category:)` directly
- `onCorrected` callback still fires after successful mutation
- Signature: `func save(graphQLClient: ApolloGraphQLClient, onDismiss: @escaping () -> Void) async`

### `CategoryPickerView`
- Remove: `import FinanceIntelligence`, `@Environment(\.transactionIntelligence)`, `previousPrediction` init param
- Add: `graphQLClient: ApolloGraphQLClient` passed through to `CategoryCorrectionViewModel`

### `CategoryPickerDestination`
- Same removals as `CategoryPickerView`
- Pass `graphQLClient` from call site (TransactionDetailView environment or init)

### `CategoryFilterPopover`
- Remove: `import FinanceIntelligence` (only needed it for `CategoryTaxonomy`, now in FinanceCore)
- No other changes

### Local `Insight` model (new)
- Add `Presentation/Shared/Models/Insight.swift`:

```swift
struct Insight: Identifiable, Sendable {
    let id: String
    let title: String
    let explanation: String
    let kind: InsightKind

    enum InsightKind: Sendable {
        case spendingSpike, categoryTrend, subscriptionDetected, unusuallyLargeTransaction
    }
}
```

### `SmartInsightsCard`
- Keep card UI unchanged
- Replace `[TransactionInsight]` → `[Insight]`
- Remove `import FinanceIntelligence`

### `AnalyticsViewModel`
- Remove: `intelligenceService` param/property, `insights: [TransactionInsight]`, `recentFluctuations`
- Add: `insights: [Insight] = []` — stays empty until GQL insights endpoint ships
- Remove the `if let service = intelligenceService { ... }` block in `load()`

### `AnalyticsAggregatorService`
- Remove: `fluctuationTransactions(from:all:)` method and `TransactionInsight` dependency
- Remove from protocol too
- `CategoryTaxonomy` import flips to `FinanceCore`

### `InsightNarrativeViewModel`
- Remove: `MLXInsightGenerator`, `NarrativeSeverity` (from FinanceIntelligence), `InsightSeverity`, `InsightGenerationContext`
- Keep: local `InsightItem` struct (already defined inline), transaction math helpers
- Add local `NarrativeSeverity` enum (info/warning/alert) in same file
- `refresh()` sets `insights = []` for now — empty until GQL narrative endpoint ships

### `TransactionsViewModel`
- Remove: `intelligenceService` param/property, `isAnalyzing`, `isPipelineRunning`, `pipelineProcessed`, `pipelineTotal`, `pipelineStage`, `pipelineTask`, `RecalculationResult`, `isRecalculating`, `recalculationResult`
- Keep: all GraphQL-backed load/delete logic
- Remove `import FinanceIntelligence`

### `AnalyticsView`
- Remove `intelligenceService` from `AnalyticsViewModel` init call
- Remove `import FinanceIntelligence`

### `DashboardView+RecentActivityCard`
- Remove `import FinanceIntelligence` (verify no other FinanceIntelligence types used)

### `TransactionDetailViewModel`
- Remove `import FinanceIntelligence`, remove any intelligence service usage

### `SettingsView` / `FeedbackExportViewModel`
- Remove `import FinanceIntelligence`, remove all feedback/export intelligence calls

### `FinanceOSMacApp`
- Remove: entire intelligence init block (IntelligenceServiceConfiguration, TransactionIntelligenceServiceImpl, CategorizationScheduler setup)
- Remove: `.environment(\.transactionIntelligence, ...)`, `.environment(\.categorizationScheduler, ...)`
- Remove: `attemptSilentModelDownload()` (ModelDownloadManager is FinanceIntelligence)
- Remove: `import Network` if only used for model download wifi check

### `ImportViewModel`
- Remove: `categorizationScheduler: CategorizationScheduler?` property and init param
- Remove: `Task.detached { await scheduler.run() }` block after upload completes
- Remove: `import FinanceIntelligence` if present

### `AdaptiveNavigation` / `DetailRouter`
- Remove: `@Environment(\.transactionIntelligence)`, `@Environment(\.categorizationScheduler)`
- Remove: `intelligenceService:` param from `TransactionsViewModel` init
- Remove: `intelligenceService:` param from `AnalyticsViewModel` init
- Remove: `categorizationScheduler:` param from `ImportViewModel` init
- Remove: `.intelligence` and `.financeAgent` cases from `detailContent` switch

### Xcode project (`project.pbxproj`)
Remove 4 entries:
- `0494F6482FC8300800800859` — `FinanceIntelligence in Frameworks` (PBXBuildFile)
- Reference in `LD_RUNPATH_SEARCH_PATHS` framework list
- `0494F6472FC8300800800859` — package product reference
- `0494F6462FC8300800800859` — XCLocalSwiftPackageReference

---

## What Does NOT Change

- `CategoryFilterPopover` rendering logic
- `CategoryPickerView` / `CategoryPickerDestination` UI
- `SmartInsightsCard` UI layout
- `AnalyticsAggregatorService.aggregateMerchants()` and `aggregateCategorySpend()`
- All GraphQL queries and mutations
- `RecategorizeMutation` — already exists in Mutations.graphql

---

## Success Criteria

1. App builds with zero `FinanceIntelligence` imports
2. `Packages/FinanceIntelligence/` directory deleted
3. Category picker opens and saves via `RecategorizeMutation`
4. Category filter popover renders taxonomy list correctly
5. `SmartInsightsCard` renders empty state (no crash)
6. Analytics view loads without intelligence service
7. No `NavigationItem.intelligence` or `.financeAgent` in nav
8. SwiftLint passes
