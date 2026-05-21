# FinanceOS macOS — UI Analysis Report

**Snapshots used:** All 65 existing snapshot PNGs (Screens, EditViews, Flows, Transactions, Components, Sheets, Charts)  
**Source files reviewed:** DashboardView, DashboardViewModel, TransactionDetailView, AccountTransactionsView, CardTransactionsView, TransactionsView, AnalyticsView, BankEditView, AccountEditView, CardEditView+Sections, SidebarView, SettingsView, ImportView

---

## 1. Dashboard (`DashboardView`)

### Visual
| # | Severity | Issue |
|---|----------|-------|
| 1 | HIGH | All recent transactions show `May 12 · 3:16 AM` — timestamps are identical across all rows; mock data uses the same `Date()` for every transaction |
| 2 | MED | The "Net Flow" hero card is visually small and left-aligned; given it's the primary KPI it deserves a full-width, more prominent treatment |
| 3 | MED | The spending trend chart has no legend; the green/red bars require prior knowledge to interpret |
| 4 | LOW | Chart background (`FDSCard`) is slightly darker than the app background, but the chart itself uses `.padding(.xs)` making bars very close to the card edge |
| 5 | LOW | "View All →" arrow-text button is not a standard macOS control; should use a proper `Button` with `buttonStyle` or `NavigationLink` affordance |
| 6 | LOW | `currentMonth` uses a fresh `DateFormatter` on every body evaluation — not cached |

### Code / Data Bugs
| # | Severity | Issue | Location |
|---|----------|-------|----------|
| 7 | HIGH | **Currency mismatch**: `formatAmount` in `DashboardView` is hardcoded to INR (`currencyCode: "INR"`, `currencySymbol: "₹"`), but `Transaction` objects store amounts in the account's native currency (USD in the test data). Dashboard shows ₹65.43 for a $65.43 USD transaction. | `DashboardView.swift:231–237` |
| 8 | MED | ViewModel fetches `limit: 5` (`recentTransactions(limit: 5)`) but `recentActivitySection` does `prefix(6)` — off-by-one; if 5 transactions are returned, the divider condition `index < min(count, 6) - 1` is still correct but the intent is wrong. | `DashboardViewModel.swift:30`, `DashboardView.swift:200` |
| 9 | MED | `categorySymbol(for:)` is a view-level string-matching heuristic duplicated separately in DashboardView vs. what the model should own. No tests for it; a merchant named "targets.csv" would match the shopping icon. | `DashboardView.swift:245–263` |
| 10 | LOW | `formatAmount` and `dateString` helpers create a new `NumberFormatter`/`DateFormatter` on every call — both should be cached or use `FormatterCache` (which already exists in FinanceUI). | `DashboardView.swift:230–243` |

---

## 2. Sidebar (`SidebarView`)

### Visual
| # | Severity | Issue |
|---|----------|-------|
| 11 | MED | The shortcut label (e.g. `⌘1`) only appears when the item is selected — making it invisible when not active. Users cannot discover the shortcuts unless they already know them. |
| 12 | LOW | `"Personal · INR"` in the brand header is **hardcoded** — it is not loaded from any user profile or settings model. |
| 13 | LOW | `"Database healthy · 2,148 txns"` in the footer is **hardcoded** string; the actual count should be dynamically fetched. |
| 14 | LOW | The `Triangle` shape used to build the logo is three separate `Triangle()` views stacked — the resulting icon renders as stacked triangles (hamburger-like), not recognizable as a financial logo. On Retina the triangles look sharp but the overall shape is ambiguous. |

---

## 3. Accounts / Cards / Banks / Transactions — Empty States

All four screens share the same empty-state pattern and all have the same issues:

| # | Severity | Issue |
|---|----------|-------|
| 15 | HIGH | **Contrast failure**: The icon (`building.columns.fill`, `creditcard.fill`, etc.) is rendered in `AppColors.Text.secondary` with an additional `.opacity(AppColors.Opacity.muted)` applied in TransactionsView — making the icon essentially invisible (~5% contrast) against `AppColors.base`. WCAG AA requires ≥ 4.5:1 for text, ≥ 3:1 for UI components. |
| 16 | HIGH | **Wasted space**: Each empty state occupies the full window height (`maxWidth: .infinity, maxHeight: .infinity`) with content centred. On a macOS window this is a sea of black with tiny text in the middle. No CTA, illustration, or guidance is offered. |
| 17 | MED | **Inconsistent copy**: Accounts says *"Import a statement to get started"*, while Transactions says *"Import statements to get started"* (plural). Banks says *"Add a bank when importing your first statement"*. Should use a single consistent copy pattern. |
| 18 | LOW | The "No Transactions" title uses `bodySmSemibold` while the subtitle uses `captionSmMedium` — the title is visually lighter than ideal for a primary state message. |

---

## 4. Transactions (`TransactionsView`)

### Visual
| # | Severity | Issue |
|---|----------|-------|
| 19 | MED | When transactions exist, the view renders each as a `FDSCard` with just merchant name + date/amount. There is no account label, card chip, or currency indicator — amounts in `$` provide no account context. |
| 20 | MED | All amounts are displayed in USD (`$`) — inconsistent with Dashboard showing ₹. The actual data uses the account's currency but the TransactionsView uses `txn.amountText` which is presumably formatted by the model layer, while Dashboard uses a custom INR formatter. |
| 21 | LOW | No page-level header when transactions are present (Dashboard has "Overview / MAY 2026"); Transactions just starts directly with the section headers. |

### Code Bugs
| # | Severity | Issue | Location |
|---|----------|-------|----------|
| 22 | MED | `groupedTransactions` is a computed property that calls `Dictionary(grouping:)` — it re-runs on every render pass including animated transitions. Should be memoized or moved to the ViewModel. | `TransactionsView.swift:100–104` |
| 23 | LOW | `formatAmount` is defined in `TransactionsView` but **never called** — dead code. Transaction amounts come from `txn.amountText`. | `TransactionsView.swift:136–143` |
| 24 | LOW | Same uncached `DateFormatter` issue as Dashboard. | `TransactionsView.swift:145–155` |

---

## 5. Transaction Detail (`TransactionDetailView`)

### Visual
| # | Severity | Issue |
|---|----------|-------|
| 25 | MED | The "DEBITED" / "CREDITED" label uses `captionSmSemibold` — it renders at roughly 10pt and is visually undersized relative to the large amount below it. |
| 26 | LOW | The `detailRow` for each field uses `.padding(.xs)` which creates tight vertical spacing between rows; combined with `Divider().opacity(AppColors.Opacity.low)` the dividers are barely visible. |

### Data Bugs
| # | Severity | Issue | Location |
|---|----------|-------|----------|
| 27 | HIGH | **Currency display**: Detail shows `$65.43` (USD from `row.amountText`) while Dashboard shows `₹65.43` (INR from its local formatter) for the same transaction. The denomination inconsistency breaks trust. | `TransactionDetailView.swift:45`, `DashboardView.swift:231` |
| 28 | MED | The `SOURCE` row shows `"Chase Checking · USD"` — currency is hardcoded from the `row.subtitle` which includes the account's currency code. No formatting or localisation is applied. | `TransactionDetailView.swift:22` |

---

## 6. Account Transactions (`AccountTransactionsView`)

### Visual
| # | Severity | Issue |
|---|----------|-------|
| 29 | HIGH | The bank name in the header shows **"Bank"** (the fallback) because `viewModel.bank` is nil in the snapshot — the bank is not loaded from the repository. The snapshot test passes `nil` as bank, but the production code also relies on an async lookup that may race against the view appearing. |
| 30 | MED | `Balance` shows "—" when `closingBalance` is nil — a more helpful label would be "No balance recorded" or omit the row entirely. |
| 31 | MED | The header uses `.font(AppTypography.bodySmMedium)` for the bank name and `.font(AppTypography.subheadline)` for the nickname — mixing AppTypography tokens with raw SwiftUI font names (`subheadline`). Should be consistent. | `AccountTransactionsView.swift:63, 66` |
| 32 | LOW | The `formattedBalance` function duplicates currency formatting logic (manual `₹\(formatted).\(frac)` string construction) that already exists in `FormatterCache` and is done differently in DashboardView. |

---

## 7. Card Transactions (`CardTransactionsView`)

### Visual
| # | Severity | Issue |
|---|----------|-------|
| 33 | MED | The header label hierarchy differs from AccountTransactionsView: card name is `title` level, card network+last4 is a chip-style row, and transaction count is `caption`. AccountTransactions uses a two-column header. The two transaction views look visually different despite representing equivalent data. |
| 34 | LOW | "Transactions: 0" as a label is developer-speak; should be "No transactions" or omitted when 0. |

---

## 8. Analytics (`AnalyticsView`)

### Visual
| # | Severity | Issue |
|---|----------|-------|
| 35 | HIGH | **Top Merchants section is completely absent** from the snapshot because the test mock provides zero merchants (`topMerchants.isEmpty == true`). There is no fallback empty state for this section — it silently disappears. |
| 36 | MED | **Missing chart legend**: Despite `.chartLegend(position: .bottom)` being set, no legend renders visibly in the snapshot. The red/green bars are unlabeled. |
| 37 | MED | The "Categories — Coming Soon" placeholder is a large empty card occupying ~30% of the visible area. There is no timeframe given and the section name "Categories" alongside a feature-flag placeholder misleads users into expecting functionality. |
| 38 | LOW | Screen title uses `AppTypography.displaySmall`; Dashboard uses `AppTypography.screenTitle`. Inconsistent title hierarchy across screens. |

### Code Quality
| # | Severity | Issue | Location |
|---|----------|-------|----------|
| 39 | HIGH | **Hardcoded raw RGB colors** throughout `AnalyticsView` instead of AppColors tokens: `Color(red: 0.945, green: 0.953, blue: 0.965)`, `Color(red: 0.741, ...)`, chart bar colors, etc. These will not update with theme changes or Dark/Light mode. | `AnalyticsView.swift:64–68, 78, 90–91, 97–98` |
| 40 | MED | `header` section uses hardcoded hex-equivalent RGB for text colors instead of `AppColors.Text.primary` / `AppColors.Text.secondary`. `spendingTrendSection` mixes one hardcoded RGB color with `AppColors.Text.secondary` for the subtitle on adjacent lines — inconsistency within the same section. | `AnalyticsView.swift:76–81` |
| 41 | LOW | Chart bar colors are also hardcoded RGB with `.opacity(0.8)` instead of `AppColors.success.opacity(...)` and `AppColors.danger.opacity(...)`. | `AnalyticsView.swift:90–98` |

---

## 9. Settings (`SettingsView`)

### Visual
| # | Severity | Issue |
|---|----------|-------|
| 42 | MED | The `Notifications` and `Auto-Refresh` toggles are **not persisted** to any storage (`@AppStorage`, `UserDefaults`, or a settings model). State is local `@State var` that resets on every app launch. |
| 43 | MED | The `About` tab is accessible from the settings sidebar but there is no snapshot coverage for it in the existing tests. |
| 44 | LOW | `linkRow` actions are empty closures `{}` — the GitHub, Bug Report, and Privacy Policy links do nothing when clicked. |
| 45 | LOW | The hardcoded build date `"2026.05.16"` in the About tab will become stale. Should be pulled from `Bundle.main.infoDictionary`. |
| 46 | LOW | `Divider().opacity(AppColors.Opacity.low)` between the sidebar and content panel is nearly invisible (very low contrast). |

---

## 10. Edit Views

### AccountEditView (`AccountEditView.swift`)

| # | Severity | Issue | Location |
|---|----------|-------|----------|
| 47 | CRITICAL | **No Save action**: `AccountEditView` uses `FDSSheet` with only `onDismiss: { dismiss() }`. There is no save button and no mechanism to persist changes to `displayName`, `ownerName`, `last4`, `nickname`, or `bankId`. All edits are silently discarded on dismiss. | `AccountEditView.swift:29–85` |
| 48 | HIGH | **Layout bug**: The `FDSLiquidButton("Delete Account")` and its wrapping `FDSCard` are **nested inside** the BANK section `FDSCard` — `FDSCard > VStack > VStack(FDSCard(Picker)) + FDSCard(DeleteButton)`. The delete card is a child of the bank card, not a sibling. This produces incorrect visual grouping. | `AccountEditView.swift:53–82` |
| 49 | MED | The `Picker` for bank selection has no styling applied — on macOS it renders as a native dropdown that visually conflicts with the dark themed form. |
| 50 | MED | There are two `.alert` modifiers — one for delete confirm and one for delete error. SwiftUI only shows the first alert that becomes active; the error alert may never display if the delete confirm alert fires simultaneously. |
| 51 | LOW | `fieldInput` for "BANK" uses `AppTypography.maskedAccount` for the label — this is a semantically incorrect token (maskedAccount is for masked numbers like "•••• 1234"). Should use `captionSmSemibold`. | `AccountEditView.swift:110` — actually this is in `BankEditView` |

### BankEditView (`BankEditView.swift`)

| # | Severity | Issue | Location |
|---|----------|-------|----------|
| 52 | CRITICAL | **No Save action**: `BankEditView` edits `name` and `providerType` state variables but never calls any save/update method. The `FDSSheet` only dismisses. Edits are silently discarded. | `BankEditView.swift:20–51` |
| 53 | HIGH | **Provider Type is a free-text field**: `providerType` maps to `Bank.ProviderType` (an enum), but the UI renders it as `FDSTextInput`. A user could type anything, which would fail to save (or silently become an invalid raw value). Should be a `Picker` / `FDSSelect`. | `BankEditView.swift:36` |
| 54 | MED | `fieldInput` uses `AppTypography.maskedAccount` for the field label font — incorrect semantic usage of a token meant for masked account numbers. | `BankEditView.swift:69` |

### CardEditView (full-screen view)

| # | Severity | Issue | Location |
|---|----------|-------|----------|
| 55 | MED | `CardEditView` uses a completely different design language from `AccountEditView`/`BankEditView`: full-screen layout with `FDSGlassSurface`, `headerBar`, `footerBar`, `scrollContent` — while the others use `FDSSheet` modal. The user sees three visually different edit experiences for conceptually equivalent tasks. | `CardEditView+Sections.swift` |
| 56 | MED | The "Create" button is disabled when `last4` is empty, but this validation only applies after the user interacts with the field — there is no inline error message explaining why Create is disabled. |
| 57 | LOW | `cardSelectionSheet` uses `.frame(minWidth: 700, maxHeight: 500)` hardcoded — not using spacing/layout tokens. |

### LedgerEditView (full-screen)

| # | Severity | Issue |
|---|----------|-------|
| 58 | HIGH | **Account Type uses a `Toggle` (checkbox)** for "Checking" — this implies the type is binary (checked = checking, unchecked = savings?). It should be a `Picker` or segmented control with all possible account types listed. |
| 59 | MED | The "Delete Bank Account" row at the bottom is a flat `FDSCard`-style container with a direct `FDSLabel` + trash icon — not using `FDSLiquidButton(.danger)` like the other edit views. Inconsistent delete affordance. |
| 60 | LOW | No label above the "Account Type" section to group it; the checkbox appears orphaned from its context. |

---

## 11. Import Flow (`ImportView`)

### Visual
| # | Severity | Issue |
|---|----------|-------|
| 61 | CRITICAL | **Import Source step is white-background** while the entire rest of the app is dark (`AppColors.base = #131415`). The import source grid renders on a pure white canvas. This is the most glaring theme violation in the app. |
| 62 | HIGH | On the white background, the section labels ("Select a source", "Banks", "Cards") render in a very light grey — near-zero contrast on white. |
| 63 | HIGH | The step indicator circles use dark-on-dark styling for incomplete steps — steps 2 and 3 show dark circles with dark numbers, unreadable on the white background of step 1. |
| 64 | MED | Bank logos (HDFC red square, ICICI "i" logo, Amex blue rectangle) appear as full-bleed image tiles with a chevron right-arrow, but the merchant name text is absent — the cards show only the logo. |

### Data Bugs
| # | Severity | Issue |
|---|----------|-------|
| 65 | MED | In `ImportFileListView` snapshot, `amex_feb.pdf` is listed with bank attribution **"Chase"** — the file is an Amex PDF assigned to a Chase bank, which is wrong mock data and indicates the bank-file association logic may have a bug in how it matches files to banks. |

### Transaction List (during import)
| # | Severity | Issue |
|---|----------|-------|
| 66 | MED | All amounts show as positive (`+₹65.43`, `+₹5,000.00`) regardless of debit/credit type — the sign is not meaningful in the import preview. The "Status" badge (Duplicate / New) is the only differentiator. |
| 67 | LOW | The "Duplicate" badge uses no fill color (grey outline) while "New" uses dark green fill — the visual weight suggests "New" is an error/warning rather than a positive state. Consider inverting or using a more neutral style for duplicates. |

---

## 12. Transaction Filter (`TransactionFilterView`)

| # | Severity | Issue |
|---|----------|-------|
| 68 | HIGH | **No selection indicator for Date Range**: The "This Month / Last Month / Last 3 Months / Last 6 Months" list has no checkmark, highlight, or radio button to show which period is currently selected. Users cannot determine the active filter. |
| 69 | MED | "Transaction Type" segmented control renders `All` with a filled background, `Debit` and `Credit` with no separator — the segment boundaries are unclear; the three options look like "All / Debit | Credit" due to a vertical divider only between Debit and Credit. |
| 70 | LOW | The "Reset" button uses a custom circle-arrow icon+text combination while "Done" is a standard `FDSLiquidButton` — inconsistent button styles in the same sheet footer. |

---

## 13. Card Selection View (`CardSelectionView`)

| # | Severity | Issue |
|---|----------|-------|
| 71 | LOW | The radio button circles on the right are plain unselected circles for all items — there is no way to see which card (if any) is pre-selected if editing an existing card. |
| 72 | LOW | The "All / HDFC Bank / ICICI Bank" filter chips render correctly, but the "All" chip uses green fill (active) while the bank chips use a grey outline (inactive). This is correct but the chip styling differs from `FDSChip` — likely a custom implementation. |

---

## 14. Components

### TransactionRow snapshot
| # | Severity | Issue |
|---|----------|-------|
| 73 | HIGH | `test_transaction_row_debit` snapshot shows **only the circular icon** — the merchant name, subtitle, and amount text are completely absent. The component appears to render only the avatar, suggesting text content is not being passed in the test or the layout is broken. |

### MetricCard snapshot
| # | Severity | Issue |
|---|----------|-------|
| 74 | MED | `test_metric_card_basic` shows `"Spent / $2,345.67"` — uses `$` (USD) while in Dashboard context the same amounts are shown as ₹. The component takes a pre-formatted `String` so this is a test data issue, but it exposes that the calling site must handle currency consistently. |

### Password Prompt snapshot
| # | Severity | Issue |
|---|----------|-------|
| 75 | HIGH | `test_password_prompt_initial` renders as **a single black horizontal bar on a white canvas** — no visible form fields, title, or content. The component is not rendering in the snapshot test environment. The `test_password_prompt_invalid` shows a red-outlined bar (error state) also on white. The entire sheet appears broken in snapshot context. |

---

## 15. Cross-Cutting Issues

| # | Severity | Issue |
|---|----------|-------|
| 76 | CRITICAL | **Systemic currency inconsistency**: Dashboard uses a hardcoded INR formatter; `TransactionDetailView`, `TransactionListContentView`, and `MetricCard` use the currency embedded in the model's `amountText` (USD for test data). Users see `₹65.43` in one screen and `$65.43` for the same transaction in another. A single shared formatter respecting the account's currency should be used everywhere. |
| 77 | HIGH | **Three different edit-view designs**: `CardEditView` (FDSGlassSurface, full-screen, headerBar/footerBar), `AccountEditView` (FDSSheet modal, FDSCard groups), `LedgerEditView` (full-screen, mixed styled rows). Editing a card vs. account vs. bank account looks like three different apps. |
| 78 | HIGH | **Missing accessibility labels**: Icon-only buttons (the `×` close button in edit sheets, the filter icon, the import footer circle icon) have no `accessibilityLabel`. The VoiceOver user will encounter unlabeled buttons. |
| 79 | MED | **Theme violation in Import**: Only the Import source step is white. All other screens are dark. This is not a dark/light mode setting — it appears to be a missing `.background(AppColors.base)` on the source step view. |
| 80 | MED | **Formatter leaks**: `DateFormatter` and `NumberFormatter` instances are created inline in `body` / computed properties across DashboardView, TransactionsView, AccountTransactionsView, and TransactionDetailView. `FormatterCache` in FinanceUI already exists for this purpose but is not used by any screen view. |
| 81 | MED | **Hardcoded colors in AnalyticsView**: Four separate files use raw `Color(red:green:blue:)` literals instead of AppColors tokens. Any future theme change must be tracked down in multiple files. |
| 82 | LOW | **No `maxWidth` constraint on Transactions, Analytics, Accounts, Cards, Banks, Settings detail**: Dashboard correctly caps at `frame(maxWidth: 1080)` but all other screens stretch edge-to-edge on wide monitors. |
| 83 | LOW | **`FDSLabel` wrapping everywhere**: `FDSLabel` is used for all text including navigation alerts (`Alert message` uses `FDSLabel` as `Text` replacement) — but `Alert` message content requires a `Text` view on some macOS versions, not a custom view. This could silently fail or display empty messages. |

---

## Priority Summary

| Priority | Count | Items |
|----------|-------|-------|
| CRITICAL | 4 | #47 (AccountEditView no save), #52 (BankEditView no save), #61 (Import white background), #76 (currency inconsistency) |
| HIGH | 14 | #7, #15, #29, #35, #39, #48, #53, #58, #62, #63, #68, #73, #75, #77 |
| MEDIUM | 30 | All remaining MED items |
| LOW | 35 | All remaining LOW items |

---

## Screens Without Full-State Snapshot Coverage

The following screens/states have **no snapshot tests** and should be added:
- AccountTransactionsView — **with transactions** (only empty state tested)
- CardTransactionsView — **with transactions**
- AnalyticsView — **with top merchants visible**
- ImportView — **upload step (step 2)** and **review step (step 3)**
- SettingsView — **About tab**
- TransactionDetailView — **no narration / empty fields**
- Any screen in **Light Mode** (all snapshots are dark mode only)
- DashboardView — **error state** (network failure)
