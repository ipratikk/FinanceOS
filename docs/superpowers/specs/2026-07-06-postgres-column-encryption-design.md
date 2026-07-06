# Postgres Column Encryption — Design

## Context

This is the third and final spec from the import-flow conversation that produced
`2026-07-05-single-screen-import-flow-design.md` (UI flow) and
`2026-07-06-password-protected-pdf-import-design.md` (password-protected PDFs).
It encrypts sensitive columns at rest in `financeos-backend`'s Postgres database:
`Transaction.narration`, `Transaction.merchant`, and `Ledger.last4`.

The database schema (`node_api/prisma/schema.prisma`) confirms all three columns
are plain `String`/`String?` with no indexes or unique constraints — encrypting
them with a non-deterministic cipher doesn't break any existing query, filter,
or sort (none exist on these columns today).

**Scope decisions confirmed at brainstorming:**
- At rest only; transit encryption remains "local dev only for now" (no TLS
  setup in this pass — a separate, later concern).
- All existing dev data is disposable — no migration/backfill script. Encrypt
  going forward only; existing data can be cleared via the already-existing
  `clearAllData` mutation if needed.
- One shared AES-256-GCM key, `DATABASE_ENCRYPTION_KEY` (base64, 32 bytes), set
  as an env var in both `node_api` and `python_service` — same trust domain
  (same docker-compose network), so no asymmetric scheme is needed here (unlike
  the password feature, which exists specifically because the client and
  backend are different trust domains).
- No key rotation in this pass — one static key, matching the password
  feature's precedent, documented limitation.

**A related leak found during brainstorming, added to scope:**
`Transaction.sourceFingerprint` (used for import dedup via
`@@unique([ledgerId, sourceFingerprint])`) is currently built by directly
concatenating the plaintext narration into a string (e.g.
`"15/03/24|SWIGGY BANGALORE|50000|0"`) and storing it as-is. Encrypting
`narration` while leaving `sourceFingerprint` untouched would leak the same
text right back out through this column. This spec replaces it with a keyed
HMAC-SHA256 hash of the same components.

## Architecture

**Dual-language write paths, one shared key.** `node_api`'s Prisma layer
handles `Ledger.last4` (via `createLedger`/`updateLedger`) and all read paths
for the three columns (GraphQL queries). But `python_service`'s
`pipeline/deduplicator.py` writes `Transaction.narration`/`merchant` via a raw
`asyncpg` `INSERT`, entirely bypassing Node/Prisma — confirmed by reading the
file directly. This means encryption logic must exist independently in both
languages, sharing one key, rather than centralizing in one place (routing
Python's writes through Node would mean rewriting the bulk-insert/dedup
pipeline's transaction model — out of scope, not a crypto-scoped change).

**Node:** a **Prisma Client Extension** (`$extends`, not the deprecated `$use`
middleware) intercepts `Ledger` and `Transaction` model operations, encrypting
`last4`/`narration`/`merchant` on `create`/`update` and decrypting them on
every read. Applied once, where the shared Prisma client is constructed — no
existing resolver (`ledger.ts`, `transaction.ts`, `upload.ts`, etc.) needs to
change; they keep calling Prisma exactly as today and see plaintext in, plaintext
out, with ciphertext only ever touching Postgres.

**Python:** `deduplicator.py`'s `bulk_insert` encrypts `narration`/`merchant`
immediately before its `INSERT`. Per-bank parser files are untouched — they
keep producing the same raw `ParsedTransaction.source_fingerprint` string as
today; only the final persist step (`deduplicator.py`) applies the HMAC
transform, keeping the security-relevant logic in one place.

**Why HMAC, not AES-GCM, for the fingerprint:** the `@@unique([ledgerId,
sourceFingerprint])` constraint and the `ON CONFLICT ("ledgerId",
"sourceFingerprint") DO NOTHING` clause both require *exact-match equality* to
work — confirmed by reading `bulk_insert` and `split_new_and_duplicates`
directly; both compare only `sourceFingerprint`, never narration/merchant.
AES-GCM's random per-call nonce means the same plaintext produces a different
ciphertext every time, which would break both the constraint and dedup
lookups outright. HMAC-SHA256 is deterministic (same input → same output,
always) and one-way (never needs to be reversed back to a narration string) —
the right tool for a compare-only, never-displayed field, structurally
different from narration/merchant/last4, which must decrypt back to their
original values for display.

**Directionality — encrypt-only vs. encrypt+decrypt:** Python only ever
*encrypts* narration/merchant (nothing in this scope needs Python to display
them back — only Node's GraphQL layer ever surfaces transactions to a user).
Node needs both `encrypt`/`decrypt` for `last4` (it both writes and reads it)
and `decrypt`-only for narration/merchant (Python is the only writer). No
unused `decrypt()` is added to Python's crypto module — YAGNI, matching this
project's established discipline.

## Components

**Node (`node_api`) — new:**
- `src/services/columnCrypto.ts` — `encrypt(plaintext: string): string` /
  `decrypt(ciphertext: string): string`, symmetric AES-256-GCM via Node's
  built-in `crypto`, same `nonce(12) ‖ ciphertext ‖ tag(16)` base64 wire
  format already proven in `passwordCrypto.ts` (this feature's key is loaded
  from `DATABASE_ENCRYPTION_KEY`, a separate env var from
  `IMPORT_PASSWORD_PRIVATE_KEY` — key separation between purposes, same
  principle already applied in the password feature). Both `encrypt` and
  `decrypt` pass `null`/`undefined` straight through unchanged, for the two
  nullable columns (`last4`, `merchant`).
- `src/prisma/encryptionExtension.ts` — the Prisma Client Extension. Encrypts
  `Ledger.last4` on `create`/`update` input; decrypts
  `last4`/`narration`/`merchant` on every query result for `Ledger` and
  `Transaction` (including nested reads, e.g. `ledger.transactions`).

**Node — modified:**
- `src/prisma/client.ts` — the exported Prisma client instance gains
  `.$extends(encryptionExtension)`.
- Fail-fast startup check: both `columnCrypto.ts` and the Node process startup
  validate `DATABASE_ENCRYPTION_KEY` is present and correctly shaped (32
  raw bytes after base64 decode) — the whole app refuses to start with a
  missing/malformed key, rather than failing unpredictably on the first DB
  operation.

**Python (`python_service`) — new:**
- `crypto/database_encryption.py` — `encrypt(plaintext: str | None) -> str |
  None` (same AES-256-GCM wire format, via the `cryptography` library —
  already a transitive dependency of `pypdf`, promoted to a direct one here
  since this module imports it explicitly) and `hmac_fingerprint(raw: str) ->
  str` (HMAC-SHA256, deterministic, hex-encoded digest). Same fail-fast
  validation of `DATABASE_ENCRYPTION_KEY` at import time.

**Python — modified:**
- `pipeline/deduplicator.py` — `bulk_insert` encrypts `t.description`
  (→`narration`) and `t.merchant` before the `INSERT`, and replaces
  `t.source_fingerprint` with `hmac_fingerprint(t.source_fingerprint)` in
  both the `INSERT` values and the `ON CONFLICT` target column.
  `split_new_and_duplicates` HMACs each incoming transaction's fingerprint
  the same way before its `WHERE "sourceFingerprint" = ANY($2)` lookup —
  comparing hash-to-hash, so dedup behavior is unchanged from today, just
  operating on hashes instead of plaintext strings.
- `python_service/requirements.txt` — add `cryptography` as a direct
  dependency (currently only pulled in transitively via `pypdf`).

## Data Flow

1. **Import (Python-only path):** a parser produces a `ParsedTransaction` with
   plaintext `description`/`merchant`/`source_fingerprint`, exactly as today.
2. `deduplicator.split_new_and_duplicates` computes `hmac_fingerprint()` for
   each incoming transaction and checks those hashes against existing hashes
   already in Postgres, identifying duplicates exactly as before (just
   comparing hashes instead of plaintext strings).
3. `deduplicator.bulk_insert` encrypts `description`→`narration` and
   `merchant`, computes the fingerprint hash, and inserts — Postgres only
   ever stores ciphertext and a hash, never the plaintext narration/merchant
   or the plaintext fingerprint string.
4. **Ledger create/update (Node path):** `createLedger`/`updateLedger`
   resolvers call Prisma exactly as today; the extension transparently
   encrypts `last4` before the write reaches Postgres.
5. **Any read (Node path):** `banks`, `ledger`, `ledgers`, `transactions`
   queries, and `uploadStatement`'s returned `ledger`, all call Prisma
   exactly as today; the extension transparently decrypts
   `last4`/`narration`/`merchant` before the resolver sees the row — GraphQL
   responses are byte-identical to today, plaintext over the wire, unchanged.

## Error Handling

- **Missing/malformed `DATABASE_ENCRYPTION_KEY`:** both services fail fast at
  startup, not lazily on first query — every DB operation now depends on this
  key, so a missing key should prevent the service from starting at all.
- **Nullable fields:** `encrypt(null)`/`decrypt(null)` for `merchant`/`last4`
  pass through as `null` — never error, never produce a ciphertext of an
  empty string.
- **Decryption failure** (corrupted/tampered ciphertext): surfaces as a clear,
  loud error — never silently returns garbage or an empty string. No key
  rotation is in scope, so a decrypt failure in practice only indicates real
  data corruption, which must never be swallowed quietly.
- **`clearAllData`:** unaffected — deletes rows outright regardless of column
  encryption.

## Testing

**Node:** unit tests for `columnCrypto.ts` (encrypt/decrypt round-trip, `null`
passthrough both directions). An integration test against the real dev
Postgres for the Prisma extension itself: create a `Ledger` with a plaintext
`last4` through the extended client, then independently read the **raw
stored row** (via a plain, non-extended client or raw SQL) and assert the
stored value is ciphertext, not plaintext — the one assertion that actually
proves encryption-at-rest, not just a pass-through — then read via the
extended client and assert it decrypts back to the original value.

**Python:** unit tests for `database_encryption.py` (`encrypt`/`decrypt`
round-trip; `hmac_fingerprint` determinism — same input twice produces
identical output). An integration test for `deduplicator.py` against the real
dev Postgres: assert `bulk_insert` stores ciphertext for `narration` and a
hash (not the raw string) for `sourceFingerprint`, and that
`split_new_and_duplicates` still correctly flags a re-imported statement as a
duplicate post-encryption.

**Cross-language interop (required, same rigor as the password-import
feature):** a fixed test key + fixed plaintext + a Python-computed ciphertext
fixture, independently verified by a Node test decrypting that exact fixture.
This is the one place a subtle format mismatch (nonce/tag layout, key
encoding) between the two languages' AES-GCM implementations would fail
silently otherwise — a self-consistency test on either language alone
wouldn't catch a real cross-language mismatch.

**Manual:** run the full import flow against a live local backend, confirm
imported transactions still display correctly in the client, and that
re-importing the same statement is still correctly detected as a duplicate.
