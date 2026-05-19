# Ledger Abstraction Design (Phase 8)

## Top-level decision

**Recommendation: Inline polymorphic fields, NOT sidecars.**

Justification: GRDB `FetchableRecord`/`PersistableRecord` is row-oriented; sidecars force every read to do a `LEFT JOIN` or two queries plus a manual stitch into a Swift `enum Ledger`. Inline keeps `Ledger` a single GRDB record, queries trivial, indexes simple. The sparsity cost (a few NULL columns per row) is negligible at FinanceOS scale (O(10²) ledgers per user). Sidecars only pay off when kind-specific data is large or independently mutated; here the kind-specific surface is 3-5 small columns.

If `loan` later needs 10+ columns (amortization schedule, EMI, interest rate, tenure), add a `loanProfiles` sidecar selectively at that point. Do not pre-pay the abstraction tax now.

---

## 1. Current problems

- `Account` and `Card` are near-isomorphic structs: both have `id`, `bankId`, displayName, last4, nickname; Card adds `linkedAccountId`, `cardType`; Account adds `ownerName`, `accountType`. Duplicated DDL, duplicated migrations, duplicated repos.
- `TransactionImportTarget` is a closed sum (`.account | .card`). Every consumer (`ParsedTransactionMapper`, `ImportTargetMatcher`, `TransactionImportPipeline`, plus app-side ViewModels and Views) switches on it. Adding `loan`/`wallet`/`crypto` requires touching every site.
- Transactions schema carries `(accountID?, cardID?)` with a CHECK xor — two FKs do the work of one. Queries like "all txns for entity X" require UNION or branching.
- `AccountRepository` and `CardRepository` protocols are structurally identical; only the row type differs. Pure duplication.
- No "product" concept (Regalia, Coral, Millennia). `cardName` overloads display name and product.
- UI picker has two parallel sections; new types require a new section per type.

---

## 2. Proposed Ledger model

### LedgerKind enum

```swift
public enum LedgerKind: String, Codable, Sendable, CaseIterable {
    case bankAccount   // savings/current
    case creditCard
    case loan          // future
    case wallet        // future (Paytm/PhonePe wallet)
    case crypto        // future
    case investment    // future (Zerodha/Groww)
}
```

String-coded to keep migrations forward-compatible.

### Ledger struct (inline polymorphic)

```swift
public struct Ledger:
    Identifiable, Codable, Sendable,
    FetchableRecord, PersistableRecord
{
    public let id: UUID
    public let bankId: UUID
    public let kind: LedgerKind

    // Universal display
    public let displayName: String       // replaces accountName / cardName
    public let last4: String             // replaces accountLast4 / cardLast4
    public let nickname: String
    public let ownerName: String         // empty for non-applicable kinds
    public let createdAt: Date

    // Bank-account-specific (NULL for other kinds)
    public let accountType: AccountType? // savings/current/credit subtype

    // Card-specific (NULL for other kinds)
    public let cardType: CardType?
    public let cardProduct: String?      // "Regalia", "Coral", "Millennia"
    public let linkedLedgerId: UUID?     // card -> funding bankAccount ledger

    public let isArchived: Bool          // soft delete instead of hard delete
}
```

### Schema DDL

```sql
CREATE TABLE ledgers (
    id              TEXT    PRIMARY KEY,
    bankId          TEXT    NOT NULL REFERENCES banks(id) ON DELETE CASCADE,
    kind            TEXT    NOT NULL,
    displayName     TEXT    NOT NULL,
    last4           TEXT    NOT NULL DEFAULT '',
    nickname        TEXT    NOT NULL DEFAULT '',
    ownerName       TEXT    NOT NULL DEFAULT '',
    createdAt       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    accountType     TEXT,                            -- nullable, bankAccount only
    cardType        TEXT,                            -- nullable, creditCard only
    cardProduct     TEXT,                            -- nullable, creditCard only
    linkedLedgerId  TEXT    REFERENCES ledgers(id) ON DELETE SET NULL,
    isArchived      INTEGER NOT NULL DEFAULT 0,
    CHECK (kind IN ('bankAccount','creditCard','loan','wallet','crypto','investment'))
);

CREATE INDEX idx_ledgers_bankId        ON ledgers(bankId);
CREATE INDEX idx_ledgers_kind          ON ledgers(kind);
CREATE INDEX idx_ledgers_bank_kind     ON ledgers(bankId, kind);
CREATE INDEX idx_ledgers_linked        ON ledgers(linkedLedgerId);
```

Index on `(bankId, kind)` answers both "all accounts at HDFC" and "all cards at HDFC" without scanning.

---

## 3. Transactions schema change

Current: `transactions(accountID TEXT NULL, cardID TEXT NULL, CHECK xor)`.

Proposed: Add `ledgerId` column, backfill from `COALESCE(accountID, cardID)`, drop old columns.

```sql
ALTER TABLE transactions ADD COLUMN ledgerId TEXT REFERENCES ledgers(id) ON DELETE CASCADE;
UPDATE transactions SET ledgerId = COALESCE(accountID, cardID);
-- Drop legacy columns in migration
```

Final: `transactions.ledgerId TEXT NOT NULL REFERENCES ledgers(id)`. No xor CHECK needed.

---

## 4. Repository layer refactor

**Single `LedgerRepository`, parameterized by `LedgerKind` for filtered fetches.**

```swift
public protocol LedgerRepository: Sendable {
    func fetchLedgers() async throws -> [Ledger]
    func fetchLedgers(bankId: UUID) async throws -> [Ledger]
    func fetchLedgers(kind: LedgerKind) async throws -> [Ledger]
    func fetchLedgers(bankId: UUID, kind: LedgerKind) async throws -> [Ledger]
    func fetchLedger(id: UUID) async throws -> Ledger?

    func insert(_ ledger: Ledger) async throws
    func update(_ ledger: Ledger) async throws
    func archive(id: UUID) async throws
    func delete(id: UUID) async throws
}
```

GRDB queries are plain chains:
```swift
try Ledger
    .filter(Ledger.Columns.bankId == bankId)
    .filter(Ledger.Columns.kind == LedgerKind.creditCard.rawValue)
    .filter(Ledger.Columns.isArchived == false)
    .fetchAll(db)
```

Old methods map 1:1:
- `fetchAccounts()` → `fetchLedgers(kind: .bankAccount)`
- `fetchCards()` → `fetchLedgers(kind: .creditCard)`

---

## 5. UI layer impact

- `TargetSelectionSection`: already unified (Phase 6); switch data source from `[Account] + [Card]` to `[Ledger]` grouped by `kind`.
- Account creation form + Card creation form → single `LedgerEditForm` with `Picker<LedgerKind>`. Conditional sub-form by kind.
- ViewModel: `LedgerEditViewModel` holds draft `Ledger`. Validation enforced before save.
- List screens: unified `LedgersListView` with kind filter chips.

---

## 6. Import pipeline impact

```swift
public enum TransactionImportTarget: Sendable, Equatable, Hashable {
    case ledger(UUID)
}
```

Reduces to a UUID wrapper. Keep the enum for future extensibility (`.split([UUID])` for joint accounts, etc).

- `ImportTargetMatcher`: input `[Ledger]` candidates; matching stays same. Returns `Ledger.id`.
- `ParsedTransactionMapper`: writes `Transaction.ledgerId` directly.
- `TransactionImportPipeline`: single code path; no per-target dispatch.
- Dedupe: key becomes `ledgerId` directly.

The `switch target` blocks collapse to direct assignment — largest simplification.

---

## 7. Migration strategy

Single `v7_ledger_unification` migration. Order:

1. Create `ledgers` table (DDL from §2)
2. Backfill from `accounts`: insert Ledger per Account, `kind='bankAccount'`, `id` preserved
3. Backfill from `cards`: insert Ledger per Card, `kind='creditCard'`, `linkedLedgerId = cards.linkedAccountId`
4. Add `transactions.ledgerId`, backfill `COALESCE(accountID, cardID)`
5. Verify: row counts match, no orphans
6. Drop old columns: `transactions.accountID`, `transactions.cardID`, drop xor CHECK
7. Drop old tables: `accounts`, `cards` last (after FK references gone)

Caveat: SQLite cannot easily add NOT NULL after backfill on older versions. Keep `ledgerId` nullable in schema, enforce NOT NULL in Swift via Ledger decoding.

### File/test change order

1. `Models/LedgerKind.swift` (new)
2. `Models/Ledger.swift` (new)
3. DatabaseManager migration v7 + test
4. `Repositories/LedgerRepository.swift` (new protocol)
5. `GRDBLedgerRepository.swift` (new impl) + tests
6. `TransactionImportTarget.swift` — collapse to `.ledger(UUID)`
7. `ImportTargetMatcher.swift` — return Ledger; update tests
8. `ParsedTransactionMapper.swift` — write ledgerId; update tests
9. `TransactionImportPipeline.swift` — remove target switch; update tests
10. App ViewModels (Accounts, Cards, Import) → Ledger
11. App Views (forms, lists, sections) → LedgerEditForm, unified lists
12. Delete `AccountRepository`, `CardRepository`, `Account.swift`, `Card.swift` (verify zero references)
13. Update `ARCHITECTURE.md`, `AGENTS.md`

---

## 8. Inline vs sidecars tradeoff

| Concern | Inline | Sidecars |
|---|---|---|
| Read path | 1 query, 1 struct | 1 query + LEFT JOIN, or 2 queries + stitch |
| Write path | 1 INSERT | 2 INSERTs in a transaction |
| Schema clarity | Sparse rows (3-4 NULL cols) | Clean per-kind tables |
| GRDB ergonomics | Native `PersistableRecord` | Custom `init(row:)`, manual associations |
| Adding `loan` with 1-3 fields | Add 1-3 nullable columns | New table + new join |
| Query "all ledgers" | Trivial | Multi-join or N+1 |

**Decision: Inline.** Revisit if any future kind crosses ~5 kind-specific columns; introduce sidecar for that kind only (hybrid is fine).

---

## 9. Code changes scope

| Area | Files | Effort |
|---|---|---|
| New models (Ledger, LedgerKind) | 2 new | S |
| Repository protocol + GRDB impl | 2 new | S |
| Delete Account/Card models + repos | 4 deleted | S |
| Database migration v7 + tests | 1 modified + 1 test | M |
| Importing layer (Target, Matcher, Mapper, Pipeline) | 4 modified | M |
| Test updates | ~15 files | M |
| App ViewModels | ~6 files | M |
| App Views | ~6 files | M |
| Documentation | 2 modified | S |
| **Total** | **~40 files** | **L** |

Sizes: S = <1h, M = 1-3h, L = aggregate. Effort: 1-2 day vertical slice if done in single branch.

---

## 10. Risk assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Migration loses transactions (FK orphan) | Low | Critical | Pre-migrate row-count assertion + DB snapshot + post-migrate verification (step 5) |
| Card→Account `linkedLedgerId` breaks | Low | High | Preserve UUIDs during backfill (keep `id` stable) |
| `cardProduct` empty after migration → UX regress | High | Low | Backfill from `cardName` heuristic, let user edit |
| Importer regressions | Med | High | Keep existing fixture tests; run HDFC+ICICI suite before+after |
| GRDB ALTER NOT NULL unsupported | Med | Low | Accept nullable in DB, enforce in Swift |
| Tests reference Account/Card directly | High | Low | Mechanical find/replace; haiku-agent can sweep |
| App ViewModels diverge from repo | Med | Med | Repo first, then VMs in separate commit |

---

## Done-when

- All transactions reachable via `SELECT * FROM transactions WHERE ledgerId = ?` (no UNION)
- `TransactionImportTarget` has single case
- Zero references to `Account` / `Card` / `AccountRepository` / `CardRepository`
- Full test suite green (importing + repos + migration + fixtures)
- HDFC and ICICI sample statements import end-to-end into ledgers
- Adding `LedgerKind.wallet` requires no changes to importing pipeline

---

## Non-breaking path

**Reject parallel-run.** Full migration as one vertical slice on a branch, gated behind debug toggle until verified. Phase 8 is pre-1.0 ingestion stabilization; no external API consumers; data migration is local SQLite. Parallel-run doubles every code path and creates dual-source-of-truth bugs.

Pre-migration: DB snapshot. Post-migration: row-count assertion aborts if mismatch — fail closed, not open.
