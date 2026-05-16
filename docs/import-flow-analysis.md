# FinanceOS Import Flow Architecture Analysis

## 1. Current Flow Diagram (ASCII)

```
                           ┌──────────────────────────────────────────────┐
                           │       Apps/FinanceOSMac (Presentation)       │
                           │                                              │
                           │   ImportView ──► ImportViewModel ──► …       │
                           │                       │                      │
                           └───────────────────────┼──────────────────────┘
                                                   ▼
            ┌─────────────────────────── 1. parseFiles() ────────────────────────┐
            │                                                                    │
            │ StatementDetector.detect(fileURL)                                  │
            │     ├─ FileTypeDetector ── ext → .csv / .txt                      │
            │     └─ InstitutionDetector ── content sniff → StatementSource     │
            │                                                                    │
            │ UnifiedStatementParser().parse(fileURL, detectedSource)            │
            │     ├─ loadRows(source) ── per-bank CSVParser/TXTParser            │
            │     └─ buildStatement(...)  (huge switch over StatementSource)     │
            │           ├─ Per-source MetadataExtractor                          │
            │           │     └─ writes accountNumber = card OR bank last4       │
            │           ├─ Per-source Mapper(header → roles)                     │
            │           └─ Per-source Normalizer(row → ParsedTransaction)        │
            │                                                                    │
            │ → ParsedStatement {                                                │
            │     bankName, accountName, accountLast4?, cardLast4?,              │
            │     transactions[ParsedTransaction], metadata? }                   │
            └────────────────────────────────────────────────────────────────────┘
                                                   │
                                                   ▼
            ┌────────────── 2. loadTargetsOnAppear() (sequential awaits) ───────┐
            │   accountRepository.fetchAccounts()                                │
            │   cardRepository.fetchCards()                                      │
            │   bankRepository.fetchBanks()                                      │
            └────────────────────────────────────────────────────────────────────┘
                                                   │
                                                   ▼
            ┌────────────── 3. autoSelectMatchingTarget() ──────────────────────┐
            │ ImportTargetMatcher.bestTarget(statement, accounts, cards, banks)  │
            │   ├─ fuzzyMatch(bank.name, statement.bankName)                     │
            │   ├─ if isCard (statement.cardLast4 != nil):                       │
            │   │     · exact match cards by bankId + cardLast4                  │
            │   │     · ELSE first card with bankId  ← FALLBACK BUG              │
            │   └─ else (statement.accountLast4 …):                              │
            │         · exact + fallback to first account at bank ← FALLBACK BUG │
            │ → TransactionImportTarget {.account(id) | .card(id)}               │
            │ then detectDuplicates(for: target) ── N×M scan, no early exit      │
            └────────────────────────────────────────────────────────────────────┘
                                                   │
                                                   ▼
            ┌────────────── 4. importTransactions() per file loop ──────────────┐
            │ TransactionImportPipeline.execute(statement, target)               │
            │   ├─ statement.transactions.map { ParsedTransactionMapper.map }    │
            │   │     · type = parsed.amountMinorUnits >= 0 ? .credit : .debit   │
            │   │     · amountMinorUnits = abs(...)                              │
            │   └─ transactionRepository.insertTransactions(transactions)        │
            │         · INSERT per-row inside one dbQueue.write{}                │
            │         · skip = SQLITE_CONSTRAINT (only mechanism for dedupe!)    │
            └────────────────────────────────────────────────────────────────────┘
```

## 2. Current Domain Model

| Entity            | Identity                                    | Notes |
|-------------------|----------------------------------------------|-------|
| `Institution`     | UUID + `name`                                | **Defined and seeded as a SQLite table but NOT referenced by Bank, Account, Card, or the import pipeline.** It is effectively dead code. |
| `Bank`            | UUID + `name`, `providerType: BankProviderType{bank, neobank, credit}` | The de-facto "institution" in the system. Banks are parented by name only — no foreign key to `Institution`. |
| `Account`         | UUID, `bankId`, `accountName`, `accountLast4`, `ownerName`, `accountType {savings, current, credit}`, `nickname` | "Bank account". `accountType` has a `.credit` case that overlaps with `Card`. |
| `Card`            | UUID, `bankId`, `linkedAccountId?`, `cardName`, `cardLast4`, `cardType {visa,…,other}`, `nickname` | Has a network type (`cardType`) but **no product/program type** (Regalia, Coral, Amazon Pay, …). |
| `Transaction`     | UUID, **mutually exclusive** `accountID?` xor `cardID?`, `postedAt`, `description`, `amountMinorUnits` (always positive), `currencyCode`, `transactionType {debit, credit}`, `sourceFingerprint?` | DB CHECK enforces xor. `sourceFingerprint` is **not indexed and not UNIQUE** in schema. |
| `ParsedTransaction` (FinanceParsers) | UUID, postedAt, description, `amountMinorUnits` **signed (debit positive, credit negative)**, currency, `sourceFingerprint`, `rewardPoints?` | Sign convention is OPPOSITE of what mapper assumes (see anti-pattern 6.3). |
| `ParsedStatement` | `bankName`, `accountName`, `accountLast4?`, `cardLast4?`, period (currently nil), totals, transactions, metadata | The presence/absence of `cardLast4` vs `accountLast4` is the **only** signal the pipeline uses to decide "is this a card statement". |
| `StatementMetadata` | customerName, customerId, **`accountNumber` overloaded for both card-last-4 AND account-last-4**, accountType, branch, ifsc, … | One field doing two jobs. |
| `StatementSource` (enum) | `.hdfcBank, .hdfcCard, .iciciBank, .iciciCard, .amex` | Combines institution + product into a single closed enum. Adding a new bank requires changes in 8+ files (detector, registry, source enum, version map, the giant switch in `buildStatement`, sources list in viewmodel, etc.). |

## 3. Domain Modeling Issues (Institution / Account / Card Confusion)

3.1 **Institution model is orphaned.** `Models/Institution.swift` + `databaseseeder_seedinstitutions` exist, but nothing in the import path or in Bank/Account/Card references `Institution.id`. The codebase has effectively renamed "institution" to "bank" without removing the old table.

3.2 **`Bank` conflates institution and product-line.** `BankProviderType.credit` (used for Amex) implies the entity is sometimes a credit-card issuer with no underlying account, sometimes a real bank. A SBI bank that also issues Amex-branded cards cannot be modeled cleanly.

3.3 **`Account` and `Card` share concept "spendable target" but have no parent abstraction.** Anywhere transactions need to be assigned, the codebase carries the `TransactionImportTarget = .account|.card` sum-type, mirrored by `TargetChoice` in the UI (which adds `.createAccount`, `.createCard`). The two-way mirroring creates brittle bindings.

3.4 **`AccountType.credit` is duplicative.** A "credit account" and a "card" are operationally the same thing. The type case should not exist.

3.5 **No "Card Product" entity.** `Card` has a network type (`visa/mastercard/…`) but seeded products ("HDFC Regalia", "ICICI Coral", "ICICI Amazon Pay") are simply written into `cardName`. There is no first-class concept of a card program.

3.6 **`StatementMetadata.accountNumber` is overloaded.** `UnifiedStatementParser.buildStatement` assigns the same `metadata?.accountNumber` to either `accountLast4` (bank sources) or `cardLast4` (card sources) depending on the `StatementSource` switch case. A single field with two semantics.

## 4. Target Resolution Bugs

4.1 **HDFC Card statement can be auto-routed to HDFC Bank Account.** In `ImportTargetMatcher.bestTarget`:
- The "isCard branch" is safe (it stays inside `.card`)
- But the fallback will pick **any** account at HDFC even if the user has multiple accounts and the statement's last4 doesn't match anything
- With multiple HDFC cards (Regalia, MoneyBack, Millennia, Diners…) the user can silently import to the wrong card

4.2 **Cross-account/cross-card mis-routing can occur.** If a card last4 is present but no card with that last4 exists, the matcher picks the first arbitrary card under the same bank. No confidence score, no abort, no user prompt.

4.3 **`fuzzyMatch` is far too permissive across banks.** `fuzzyMatch("HDFC", "HDFC Bank")` returns true, but permissive matching can cause cross-bank mis-routing.

4.4 **Statement → Bank name uses `StatementSource.bankName` literal**. If a user renames their bank to "American Express" via UI, auto-resolution silently breaks.

4.5 **Account-vs-card discriminator is fragile.** "isCard" is decided by `statement.cardLast4 != nil`. If card metadata extraction fails, it falls back to `nil`, and the matcher routes to a bank account — silently mixing card transactions onto the wrong target.

4.6 **Card last4 extraction is brittle.** Recent fix history shows whitespace/empty-string regressions; implementation depends on lexical positions in unknown statement formats.

## 5. Anti-patterns

5.1 **"`HDFC •••• 1234`" naming redundancy.** Both `createCard` and `createAccount` build display names as `"<bankName> •••• <last4>"`, then store in `cardName` / `accountName`. The bank is already a foreign key — this denormalizes data.

5.2 **`ImportView` has TWO target Pickers** with subtly different behavior. Both write to the same `targetChoice` but render different sections. Duplicate UI for the same state.

5.3 **Sign convention inversion buried inside normalizers.**
- `ParsedTransaction.amountMinorUnits` is positive for debit, negative for credit
- `ParsedTransactionMapper.map` does: `transactionType = parsed.amountMinorUnits >= 0 ? .credit : .debit`
- **This is inverted.** Every HDFC Bank and ICICI Bank transaction gets the wrong `transactionType`.

5.4 **The "Mapper / Normalizer / MetadataExtractor / Parser" trio is replicated five times** — once per `StatementSource`. Adding a new bank requires touching the enum, detector, registry, switch, and view-model literal.

5.5 **`UnifiedStatementParser` reads the full file as `String(contentsOf:utf8)` upfront** and again as rows. For larger statements, two passes.

5.6 **`supportedSources` is a literal in the view model**. The truth lives in `StatementSource`; the view model re-encodes which are "fully supported" via string-equality check. Stale flag.

5.7 **`reset()` clears `banks`, `accounts`, `cards`** alongside the file selection — every re-open has to re-fetch the entire repositories.

5.8 **`DispatchGroup` in `onDrop`** mixes callbacks with `@MainActor` and reads from a potentially-racing `urls` array.

5.9 **`DefaultTransactionImporter` is never invoked.** Two parallel entry points; one is dead.

## 6. Blocking Architectural Issues

6.1 **No `Institution` foreign key on `Bank`/`Account`/`Card`.** The model needs `Institution` to be the parent of `Bank` (or the orphaned table removed).

6.2 **`TransactionImportTarget` is a closed sum on `account|card`.** Any new spendable type (loan, wallet, brokerage) requires changing every consumer.

6.3 **Sign convention is inverted end-to-end.** This is a **correctness blocker** for every analytics surface that depends on `transactionType`. Spending totals are inverted for HDFC and ICICI rows.

6.4 **Deduplication is two layers and both are weak.**
- *Layer A (preview):* uses `String(combined.hashValue)` which is **not stable across launches**.
- *Layer B (persist):* relies on a UNIQUE constraint that **does not exist** in the schema. Re-importing silently inserts duplicates.

6.5 **Sequential per-file pipeline execution** inside `performImport` — each file does its own `dbQueue.write` round-trip. Multi-file imports are not atomic.

6.6 **`UnifiedStatementParser` is synchronous and on the MainActor task** — blocking the UI on large files.

6.7 **`StatementSource` is a god-enum** — dispatches parsing, type the detector returns, type the UI uses, type the view model exposes.

## 7. UI / Data Coupling Points

| Coupling | Location | Problem |
|----------|----------|---------|
| `ImportPreviewView` imports `FinanceParsers` directly | `ImportPreviewView.swift:2` | View reaches across package boundaries; `ParsedStatement` types leak into UI. |
| `TargetChoice` mirrors `TransactionImportTarget` | `ImportView.swift:6-11` | Two-way `onChange` sync creates brittle bindings. |
| `ImportViewModel.supportedSources` literal | `ImportViewModel.swift:30-38` | View redeclares parser registry — stale flag. |
| `CreateNewTargetSheet` is unaware of metadata | `CreateNewTargetSheet.swift` | Metadata that suggested values is discarded by prefill time. |
| `ImportPreviewView.handleTargetSelection` initializes view-local state | `ImportPreviewView+Sections.swift:60-113` | View doing view-model work. |
| `loadTargetsOnAppear()` called from `.onAppear` | `ImportView.swift:28-31` | Every navigation away/back causes re-fetch. |
| Bi-directional target binding loop | `ImportView.swift:44-69` | `TargetChoice` ↔ `TransactionImportTarget` ping-pong on changes. |
| `fuzzyMatch` implemented twice | view + domain | Two implementations of the same logic. |

## 8. Threading / Blocking Risks

8.1 **`UnifiedStatementParser` runs on MainActor task.** Large file reads block the main thread.

8.2 **`detectDuplicates` is O(F × T × E)** — runs on MainActor with no early termination or async batching.

8.3 **DispatchGroup in `onDrop`** with unsynchronized `urls.append` can race.

8.4 **`AppContainer` is `@MainActor` singleton.** Every repository call must hop off MainActor.

8.5 **`performImport` per-file awaits in sync loop** — no `TaskGroup` parallelism, no progress callback beyond boolean `isLoading`.

## 9. Dedupe Weaknesses

9.1 **No canonical fingerprint across preview and persist.**
- Normalizer produces `sourceFingerprint` using raw input strings
- Preview dedupe uses `ISO8601DateFormatter().string(from:)` + amount + lowercased description
- Two independent shapes never reconcile

9.2 **`sourceFingerprint` is not unique in the DB.** `Transaction.createTable` has no UNIQUE constraint. Re-importing inserts every row again.

9.3 **Fingerprints embed sign/credit/debit**, not the signed amount. If sign convention changes, all fingerprints change.

9.4 **`description` normalization is inconsistent.** Preview does `.trimmingCharacters(...).lowercased()`, fingerprint uses raw.

9.5 **`String(combined.hashValue)` — `hashValue` is randomized per process in Swift.** Dedupe results are not reproducible across launches.

9.6 **Statement period not propagated.** Two distinct months with same-date/same-amount/same-description can collide.

9.7 **No reward-points awareness.** Parsed but never persisted or used as tiebreaker.

9.8 **No card vs account isolation.** If a card and account on same day have same description+amount, the preview hash collides.

## 10. Metadata Propagation Gaps

10.1 **`StatementMetadata.accountNumber` is overloaded.**

10.2 **`StatementMetadata` lives in FinanceParsers** — repositories can't use it without leaking the parser package.

10.3 **No `StatementPeriodStart`/`StatementPeriodEnd` parsing.** Always `nil`. Cannot detect overlapping imports.

10.4 **`StatementSource` doesn't reach persistence.** No `Transaction.sourceStatementID` or `Statement` table. No audit trail.

10.5 **`ParsedTransaction.id`** is regenerated every parse and never used.

10.6 **`accountName`** filled from `metadata?.customerName` — customer name becomes account label, wrong cardinality.

10.7 **`ownerName` only on account creation**, not cards. Co-held cards cannot be modeled.

10.8 **`rewardPoints` extracted, not stored.** Lost data per import.

10.9 **`StatementMetadata.accountType`** mapped to `.savings` for everything. Type information destroyed silently.

10.10 **No statement-file provenance.** Cannot answer "which statement did this come from" or "re-import only the last statement."

---

## 11. Proposed Normalized Terminology (Not Yet Implemented)

| Current | Proposed | Notes |
|---------|----------|-------|
| `Bank` (entity) | `Institution` | Promote `Institution.id` to FK key everywhere, retire orphan table. |
| `BankProviderType{bank, neobank, credit}` | `InstitutionKind{bank, neobank, cardIssuer, brokerage, …}` | Open-ended, institution-level classification. |
| `Account` + `Card` | `Ledger` (umbrella) with `kind: LedgerKind{bankAccount, creditCard, loan, wallet}` | Single spendable target; `Card`-specific fields in sidecar or polymorphic columns. |
| `AccountType.credit` | removed | Express through `LedgerKind.creditCard`. |
| `Card.cardName` containing "HDFC •••• 1234" | split into `nickname` (user) + `product` (e.g., "Regalia") + `last4` (computed in UI) | Stop denormalizing. |
| `cardLast4` / `accountLast4` | unified `ledgerLast4`; discriminator is `Ledger.kind`, not optional presence | Eliminates the "if cardLast4 != nil" branch. |
| `StatementSource` (enum) | `StatementSchema { institutionID, productKey, version }` (value type) | Open registry; add institution without touching every site. |
| `StatementMetadata.accountNumber` (overloaded) | split into `ledgerLast4` and `productHint` | One field, one job. |
| `ParsedTransaction.amountMinorUnits` (signed) | `signedAmountMinorUnits` with explicit "negative = outflow" convention documented once **or** `(absoluteAmountMinorUnits, direction: TransactionDirection)` | Pick one; current implicit sign is the root of bug 6.3. |
| `TransactionType{debit, credit}` | `TransactionDirection{outflow, inflow}` | "Credit" overloads bank and card accounting conventions. |
| `sourceFingerprint: String` | `Fingerprint { schemaVersion, scope: LedgerID, parts: [String] }` + DB UNIQUE INDEX `(ledger_id, fingerprint_v2)` | Fingerprint scoped to ledger, deterministic, and sole dedupe key. |
| `TransactionImporting` + `DefaultTransactionImporter` + `TransactionImportPipeline` | one `ImportPipeline` with stages `[detect, parse, normalize, enrich, dedupe, persist]` | Single entry point. |

---

## 12. Recommended Phase Plan

1. **Domain remodel proposal** → produces a single proposal doc covering Institution↔Bank merge, Ledger umbrella, sign-convention contract, fingerprint v2 schema. Expected: written proposal + migration plan, no code changes.

2. **Fix sign-convention bug** in `ParsedTransactionMapper.map` and add end-to-end test for `transactionType` per source. Expected: corrected mapper + 5 unit tests.

3. **Add UNIQUE INDEX** on `(ledger_id, sourceFingerprint)` via GRDB migration; make dedup work at persistence layer. Expected: new `AppMigration` step + repo test asserting `skipped > 0` on re-import.

4. **Tighten `ImportTargetMatcher`** to require last4 match, returning `nil` (forcing user choice) when fallback would be ambiguous. Add coverage for HDFC-card → HDFC-account regression. Expected: matcher rewrite + 6 unit tests.

5. **Hoist `supportedSources`** into `StatementSourceRegistry.supportedSources`, delete the literal in `ImportViewModel`. Expected: registry + view-model edit.

6. **Collapse `TargetChoice` ↔ `TransactionImportTarget` mirroring** into a single `selectedTarget` SwiftUI binding sourced from the view model. Expected: removed two `.onChange` loops.

7. **Remove dead code**: orphan `Institution.swift` + `seedInstitutions` (after step 1 picks direction); unused `FinanceCore.DefaultTransactionImporter` wrapper. Expected: file deletions or migration to use Institution.

8. **Design `Ledger`-umbrella migration** (hold until steps 1–4 are complete). Expected: migration script + repo-layer rewrite plan.

---

## Done-when Criteria

- `ImportTargetMatcher` rejects "first card at bank" fallback in a unit test simulating HDFC-card statement against user with no matching card last4.
- `transactionType` for an imported HDFC Bank debit row equals `.debit` in an end-to-end repository test.
- Re-importing the exact same CSV produces `ImportResult(inserted: 0, skipped: N)` where N == row count.
- `ImportViewModel.supportedSources` is gone; the value comes from a registry imported from FinanceParsers.
- `Institution` either drives `Bank`/`Ledger` FKs or is removed; exactly one "institution" table in schema.

---

## Risk: Sign-Convention Migration

The sign-convention fix (Phase 2) silently rewrites the meaning of `transactionType` in existing rows. Without a one-time DB migration that re-derives `transactionType` from historical data, dashboards flip in opposite directions for old vs new imports. A migration script must accompany the fix, or a `parserSchemaVersion` column on `Transaction` so each row is interpreted under its own convention.
