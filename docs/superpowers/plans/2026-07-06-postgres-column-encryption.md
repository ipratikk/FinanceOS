# Postgres Column Encryption Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Encrypt `Transaction.narration`, `Transaction.merchant`, and `Ledger.last4`
at rest in Postgres, and close a related plaintext leak in
`Transaction.sourceFingerprint`.

**Architecture:** One shared AES-256-GCM key (`DATABASE_ENCRYPTION_KEY`) used
independently by both languages that touch these columns: `node_api` (Prisma
Client Extensions — a `query` component encrypts on `ledger.create`/`update`,
a `result` component decrypts on every read of `Ledger.last4` and
`Transaction.narration`/`merchant`, verified to compose correctly through
nested `include`s) and `python_service` (`pipeline/deduplicator.py`'s raw
`asyncpg` insert path, the one place that writes `Transaction` rows without
going through Node/Prisma at all). `sourceFingerprint` becomes a keyed
HMAC-SHA256 hash instead of a plaintext string, preserving exact-match dedup.

**Tech Stack:** Node's built-in `crypto` module (no new npm dependency),
Python's `cryptography` library (already a transitive dependency of `pypdf`,
promoted to direct here), Prisma Client Extensions (`$extends`, stable since
Prisma 4.16 — no preview flags needed on the 5.13.0 already pinned in this
repo).

This plan is backend-only (`FinanceOS-Backend`) — no client changes, since
GraphQL responses are unchanged (plaintext in, plaintext out; only the
Postgres storage layer changes).

Design spec: `docs/superpowers/specs/2026-07-06-postgres-column-encryption-design.md`.

## Global Constraints

- One shared `DATABASE_ENCRYPTION_KEY` (base64, 32 raw bytes) — a separate
  env var from `IMPORT_PASSWORD_PRIVATE_KEY` (key separation between
  purposes, same principle as the password feature).
- Wire format for encrypted values: `nonce (12 bytes) ‖ ciphertext ‖ tag (16
  bytes)`, base64-encoded — matches the `AES.GCM.SealedBox.combined`-style
  layout already used by `passwordCrypto.ts`, verified interoperable between
  Node's `crypto` and Python's `cryptography` library (see Task 2).
- `sourceFingerprint` uses HMAC-SHA256 (deterministic, one-way) — never
  AES-GCM (non-deterministic, would break the `@@unique([ledgerId,
  sourceFingerprint])` constraint and `ON CONFLICT` dedup).
- No migration/backfill of existing data — dev-only, disposable (confirmed
  at brainstorming). Encrypt going forward only.
- No key rotation in this pass — one static key, documented limitation.
- Both services fail fast at startup (module-import time) if
  `DATABASE_ENCRYPTION_KEY` is missing or not 32 raw bytes after base64
  decoding — never fail lazily on the first DB operation.
- `encrypt`/`decrypt` on both languages pass `None`/`null` straight through
  unchanged (for nullable `merchant`/`last4`).
- Python's `ParsedTransaction` (`models/schemas.py`) has **no `merchant`
  field** — confirmed by reading the file directly. `deduplicator.py`'s
  `bulk_insert` has always inserted a literal `NULL` for `merchant`; there is
  no merchant plaintext anywhere in the import pipeline to encrypt. Do not
  add a `merchant`-encrypt step to `bulk_insert` — there's nothing to
  encrypt. The Node-side `result` extension for `Transaction.merchant` is
  still built (forward-looking, costs nothing since `decrypt(null)` is a
  no-op), but Python's write path needs no corresponding change for it.

---

## File Structure

**`FinanceOS-Backend/python_service/`:**
- Create: `crypto/database_encryption.py`, `crypto/__init__.py`
- Modify: `pipeline/deduplicator.py`, `requirements.txt`
- Test: `tests/test_database_encryption.py`, `tests/test_deduplicator.py` (new — no
  existing test file for this module)

**`FinanceOS-Backend/node_api/`:**
- Create: `src/services/columnCrypto.ts`, `src/prisma/encryptionExtension.ts`
- Modify: `src/prisma/client.ts`
- Test: `src/services/columnCrypto.test.ts`, `src/prisma/encryptionExtension.test.ts` (new)

---

## Task 1: Python — `database_encryption.py` (AES-256-GCM + HMAC)

**Files:**
- Create: `python_service/crypto/__init__.py` (empty)
- Create: `python_service/crypto/database_encryption.py`
- Modify: `python_service/requirements.txt`
- Test: `python_service/tests/test_database_encryption.py`

**Interfaces:**
- Produces: `encrypt(plaintext: str | None) -> str | None`,
  `decrypt(ciphertext: str | None) -> str | None`, `hmac_fingerprint(raw:
  str) -> str` (hex-encoded SHA-256 HMAC digest). Both `encrypt`/`decrypt`
  raise at import time (module load) if `DATABASE_ENCRYPTION_KEY` is unset
  or not exactly 32 bytes after base64 decoding.

- [ ] **Step 1: Generate a test-only fixture key and encrypted value**

This fixture (committed, safe — never the real deployment key) is used by
this task's own tests and by Task 2's cross-language interop test. It was
generated and verified with the exact library/version pinned in this task
(Python's `cryptography==49.0.0`, already resolved in this repo's venv as a
transitive dependency of `pypdf`) and independently confirmed decryptable
by Node's built-in `crypto` module:

```
DATABASE_ENCRYPTION_KEY fixture (base64): U8tnbclQVVEUNzwLJnolbbWQMQuJsWT0zscl3Y9ppQI=
Plaintext: SWIGGY BANGALORE
Sealed payload (base64, nonce=all-zero for determinism — real code never reuses a nonce): AAAAAAAAAAAAAAAATcnnQwD0zPLEOm1Lv34+K2YUzKOnO+tl8/Ej/WNNwRI=
```

No action needed here — these values are used directly in Step 3 and in
Task 2.

- [ ] **Step 2: Add `cryptography` to requirements**

Add to `python_service/requirements.txt`:
```
cryptography==49.0.0
```
Run: `pip install -r python_service/requirements.txt`

- [ ] **Step 3: Write the failing tests**

Create `python_service/crypto/__init__.py` (empty file — makes `crypto` a
package):
```python
```

Create `python_service/tests/test_database_encryption.py`:

```python
import os
import pytest
from crypto.database_encryption import encrypt, decrypt, hmac_fingerprint

FIXTURE_KEY_B64 = "U8tnbclQVVEUNzwLJnolbbWQMQuJsWT0zscl3Y9ppQI="
FIXTURE_COMBINED_B64 = "AAAAAAAAAAAAAAAATcnnQwD0zPLEOm1Lv34+K2YUzKOnO+tl8/Ej/WNNwRI="
FIXTURE_PLAINTEXT = "SWIGGY BANGALORE"


@pytest.fixture(autouse=True)
def _set_key(monkeypatch):
    monkeypatch.setenv("DATABASE_ENCRYPTION_KEY", FIXTURE_KEY_B64)


def test_encrypt_decrypt_round_trip():
    ciphertext = encrypt("some narration text")
    assert ciphertext != "some narration text"
    assert decrypt(ciphertext) == "some narration text"


def test_encrypt_none_passes_through():
    assert encrypt(None) is None


def test_decrypt_none_passes_through():
    assert decrypt(None) is None


def test_decrypt_fixture_produced_by_the_documented_wire_format():
    # Uses the exact fixture from Step 1 — decrypting it directly (bypassing
    # the normal random-nonce encrypt() path) proves this module's decrypt()
    # correctly parses the nonce(12)||ciphertext||tag(16) layout, which is
    # what Task 2's Node-side interop test also verifies independently.
    assert decrypt(FIXTURE_COMBINED_B64) == FIXTURE_PLAINTEXT


def test_hmac_fingerprint_is_deterministic():
    raw = "15/03/24|SWIGGY BANGALORE|50000|0"
    assert hmac_fingerprint(raw) == hmac_fingerprint(raw)


def test_hmac_fingerprint_differs_for_different_input():
    assert hmac_fingerprint("a") != hmac_fingerprint("b")


def test_hmac_fingerprint_matches_known_fixture():
    # Independently computed with a fixed HMAC key via the same library/version.
    import hmac as hmac_module
    import hashlib
    fixture_hmac_key = "HxnzX2N1xeeGwRqy11P9lVvJKy0DTp4DRz+4KE8Bdww="
    raw = "15/03/24|SWIGGY BANGALORE|50000|0"
    expected = "0b9220310b001d9d3dada5c7d91fb38044fbbab7193f10dd675d3398d7fda8c2"

    import base64
    key_bytes = base64.b64decode(fixture_hmac_key)
    actual = hmac_module.new(key_bytes, raw.encode(), hashlib.sha256).hexdigest()
    assert actual == expected  # sanity-checks the fixture itself, not the module


def test_missing_key_raises_at_import(monkeypatch):
    monkeypatch.delenv("DATABASE_ENCRYPTION_KEY", raising=False)
    import importlib
    import crypto.database_encryption as mod
    with pytest.raises(RuntimeError):
        importlib.reload(mod)
    # Restore for subsequent tests in this file
    monkeypatch.setenv("DATABASE_ENCRYPTION_KEY", FIXTURE_KEY_B64)
    importlib.reload(mod)
```

- [ ] **Step 4: Run tests to verify they fail**

Run: `cd python_service && python -m pytest tests/test_database_encryption.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'crypto.database_encryption'`

- [ ] **Step 5: Implement `database_encryption.py`**

Create `python_service/crypto/database_encryption.py`:

```python
import base64
import hashlib
import hmac
import os

from cryptography.hazmat.primitives.ciphers.aead import AESGCM

_KEY_ENV_VAR = "DATABASE_ENCRYPTION_KEY"


def _load_key() -> bytes:
    raw = os.environ.get(_KEY_ENV_VAR)
    if not raw:
        raise RuntimeError(f"{_KEY_ENV_VAR} is not set")
    key = base64.b64decode(raw)
    if len(key) != 32:
        raise RuntimeError(f"{_KEY_ENV_VAR} must decode to exactly 32 bytes, got {len(key)}")
    return key


_KEY = _load_key()


def encrypt(plaintext: str | None) -> str | None:
    if plaintext is None:
        return None
    nonce = os.urandom(12)
    aesgcm = AESGCM(_KEY)
    ciphertext_with_tag = aesgcm.encrypt(nonce, plaintext.encode("utf-8"), None)
    combined = nonce + ciphertext_with_tag
    return base64.b64encode(combined).decode("ascii")


def decrypt(ciphertext: str | None) -> str | None:
    if ciphertext is None:
        return None
    combined = base64.b64decode(ciphertext)
    nonce = combined[:12]
    ciphertext_with_tag = combined[12:]
    aesgcm = AESGCM(_KEY)
    plaintext = aesgcm.decrypt(nonce, ciphertext_with_tag, None)
    return plaintext.decode("utf-8")


def hmac_fingerprint(raw: str) -> str:
    return hmac.new(_KEY, raw.encode("utf-8"), hashlib.sha256).hexdigest()
```

Note: `hmac_fingerprint` uses the same `DATABASE_ENCRYPTION_KEY` as
`encrypt`/`decrypt` — one shared key for this whole module, not a second
key. This is intentional per the design spec ("one shared AES-256-GCM key")
and is safe because HMAC-SHA256 and AES-256-GCM are cryptographically
independent uses of the same key material.

- [ ] **Step 6: Run tests to verify they pass**

Run: `cd python_service && python -m pytest tests/test_database_encryption.py -v`
Expected: 8 passed

- [ ] **Step 7: Commit**

```bash
git add python_service/crypto/ python_service/tests/test_database_encryption.py python_service/requirements.txt
git commit -m "feat(crypto): add AES-256-GCM column encryption + HMAC fingerprinting"
```

---

## Task 2: Node — `columnCrypto.ts` (AES-256-GCM) + cross-language interop

**Files:**
- Create: `node_api/src/services/columnCrypto.ts`
- Test: `node_api/src/services/columnCrypto.test.ts`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: `encrypt(plaintext: string | null): string | null`,
  `decrypt(ciphertext: string | null): string | null`. Both throw at module
  load if `DATABASE_ENCRYPTION_KEY` is unset or not 32 raw bytes.

- [ ] **Step 1: Write the failing tests**

Create `node_api/src/services/columnCrypto.test.ts`:

```typescript
import { test } from 'node:test';
import assert from 'node:assert';

const FIXTURE_KEY_B64 = 'U8tnbclQVVEUNzwLJnolbbWQMQuJsWT0zscl3Y9ppQI=';
const FIXTURE_COMBINED_B64 =
  'AAAAAAAAAAAAAAAATcnnQwD0zPLEOm1Lv34+K2YUzKOnO+tl8/Ej/WNNwRI=';
const FIXTURE_PLAINTEXT = 'SWIGGY BANGALORE';

process.env.DATABASE_ENCRYPTION_KEY = FIXTURE_KEY_B64;
import { encrypt, decrypt } from './columnCrypto';

test('encrypt/decrypt round trip', () => {
  const ciphertext = encrypt('some narration text');
  assert.notStrictEqual(ciphertext, 'some narration text');
  assert.strictEqual(decrypt(ciphertext), 'some narration text');
});

test('encrypt(null) passes through', () => {
  assert.strictEqual(encrypt(null), null);
});

test('decrypt(null) passes through', () => {
  assert.strictEqual(decrypt(null), null);
});

test('decrypts a fixture produced by Python\'s cryptography library', () => {
  // Cross-language interop: this exact ciphertext was generated in Python
  // (Task 1's fixture) and independently verified decryptable there too —
  // this test proves Node's decrypt() parses the same nonce||ct||tag wire
  // format identically.
  assert.strictEqual(decrypt(FIXTURE_COMBINED_B64), FIXTURE_PLAINTEXT);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd node_api && npm test -- src/services/columnCrypto.test.ts`
Expected: FAIL — `Cannot find module './columnCrypto'`

- [ ] **Step 3: Implement `columnCrypto.ts`**

Create `node_api/src/services/columnCrypto.ts`:

```typescript
import crypto from 'crypto';

const KEY_ENV_VAR = 'DATABASE_ENCRYPTION_KEY';

function loadKey(): Buffer {
  const raw = process.env[KEY_ENV_VAR];
  if (!raw) {
    throw new Error(`${KEY_ENV_VAR} is not set`);
  }
  const key = Buffer.from(raw, 'base64');
  if (key.length !== 32) {
    throw new Error(`${KEY_ENV_VAR} must decode to exactly 32 bytes, got ${key.length}`);
  }
  return key;
}

const KEY = loadKey();

export function encrypt(plaintext: string | null): string | null {
  if (plaintext === null) return null;
  const nonce = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', KEY, nonce);
  const ciphertext = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();
  const combined = Buffer.concat([nonce, ciphertext, tag]);
  return combined.toString('base64');
}

export function decrypt(ciphertext: string | null): string | null {
  if (ciphertext === null) return null;
  const combined = Buffer.from(ciphertext, 'base64');
  const nonce = combined.subarray(0, 12);
  const tag = combined.subarray(combined.length - 16);
  const encrypted = combined.subarray(12, combined.length - 16);
  const decipher = crypto.createDecipheriv('aes-256-gcm', KEY, nonce);
  decipher.setAuthTag(tag);
  const plaintext = Buffer.concat([decipher.update(encrypted), decipher.final()]);
  return plaintext.toString('utf8');
}
```

Note: `KEY = loadKey()` runs at module load, so importing this file with
`DATABASE_ENCRYPTION_KEY` unset throws immediately — matching the
fail-fast-at-startup global constraint. The test file sets
`process.env.DATABASE_ENCRYPTION_KEY` **before** its `import` line for
exactly this reason (ES module imports are hoisted, but the explicit
`process.env` assignment on the line above still executes before the
imported module's top-level code runs, since `ts-node/register`'s CJS
transpilation preserves source order for `require`-based imports issued via
`import` syntax in this project's `"module": "commonjs"` config).

- [ ] **Step 4: Run test to verify it passes**

Run: `cd node_api && npm test -- src/services/columnCrypto.test.ts`
Expected: 4 tests pass

- [ ] **Step 5: Commit**

```bash
git add node_api/src/services/columnCrypto.ts node_api/src/services/columnCrypto.test.ts
git commit -m "feat(crypto): add Node-side AES-256-GCM column encryption"
```

---

## Task 3: Node — Prisma Client Extensions (encrypt-on-write, decrypt-on-read)

**Files:**
- Create: `node_api/src/prisma/encryptionExtension.ts`
- Modify: `node_api/src/prisma/client.ts`
- Test: `node_api/src/prisma/encryptionExtension.test.ts`

**Interfaces:**
- Consumes: `encrypt`/`decrypt` from Task 2's `columnCrypto.ts`.
- Produces: an extended Prisma client (exported from `client.ts`, unchanged
  export shape) where every existing resolver that reads/writes
  `Ledger.last4`, `Transaction.narration`, or `Transaction.merchant`
  continues to work completely unmodified — no resolver file changes in
  this task.

This task's design was verified empirically against the real Prisma 5.13.0
client and a live Postgres before being written: a `result` extension
component (not a `query` component) is the correct mechanism for
decrypt-on-read, because it is the only one confirmed to compose correctly
through nested `include`s (e.g. `bank.findUnique({ include: { ledgers: true
} })` correctly decrypting the nested `ledgers[0].last4`). A `query`
component correctly handles encrypt-on-write for `create`/`update`, and was
confirmed to chain cleanly with this file's *existing* `.$extends()` call
(the ID-generation extension already there for `bank.create`/`ledger.create`
— do not remove or replace it, add alongside it).

- [ ] **Step 1: Write the failing test**

Create `node_api/src/prisma/encryptionExtension.test.ts`. This is an
integration test against the real dev Postgres (already running via
`docker compose up -d` in this repo) — it is the only way to prove
encryption is actually happening at rest, not just a pass-through:

```typescript
import { test } from 'node:test';
import assert from 'node:assert';
import { PrismaClient } from '@prisma/client';
import prisma from './client';

const rawClient = new PrismaClient();

test('last4 is encrypted at rest and decrypted on read', async () => {
  const bank = await rawClient.bank.create({
    data: { name: 'Encryption Test Bank', code: `ENCTEST${Date.now()}` },
  });

  const ledger = await prisma.ledger.create({
    data: { displayName: 'Encryption Test Ledger', kind: 'BANK_ACCOUNT', last4: '4242', bankId: bank.id },
  });

  // The critical assertion: read the RAW row via the unextended client.
  // If this is plaintext '4242', encryption isn't happening.
  const raw = await rawClient.ledger.findUnique({ where: { id: ledger.id } });
  assert.notStrictEqual(raw?.last4, '4242');

  // Read via the extended client — should transparently decrypt back to '4242'.
  const decrypted = await prisma.ledger.findUnique({ where: { id: ledger.id } });
  assert.strictEqual(decrypted?.last4, '4242');

  // Nested include — the specific case a naive query-only extension would miss.
  const bankWithLedgers = await prisma.bank.findUnique({
    where: { id: bank.id },
    include: { ledgers: true },
  });
  assert.strictEqual(bankWithLedgers?.ledgers[0]?.last4, '4242');

  await rawClient.ledger.delete({ where: { id: ledger.id } });
  await rawClient.bank.delete({ where: { id: bank.id } });
});

test('null last4 round-trips as null', async () => {
  const bank = await rawClient.bank.create({
    data: { name: 'Encryption Test Bank 2', code: `ENCTEST2${Date.now()}` },
  });
  const ledger = await prisma.ledger.create({
    data: { displayName: 'No Last4 Ledger', kind: 'WALLET', bankId: bank.id },
  });
  const read = await prisma.ledger.findUnique({ where: { id: ledger.id } });
  assert.strictEqual(read?.last4, null);

  await rawClient.ledger.delete({ where: { id: ledger.id } });
  await rawClient.bank.delete({ where: { id: bank.id } });
});
```

- [ ] **Step 2: Run test to verify it fails**

Ensure the local backend is running: `cd .. && docker compose up -d` (from
the repo root, if not already up — check with `docker compose ps` first).

Run: `cd node_api && npm test -- src/prisma/encryptionExtension.test.ts`
Expected: FAIL — `Cannot find module './encryptionExtension'`, or the
`last4` assertions fail since no encryption exists yet (either failure mode
is an acceptable "fails for the right reason" — the module doesn't exist).

- [ ] **Step 3: Implement `encryptionExtension.ts`**

Create `node_api/src/prisma/encryptionExtension.ts`:

```typescript
import { Prisma } from '@prisma/client';
import { encrypt, decrypt } from '../services/columnCrypto';

export const encryptOnWrite = Prisma.defineExtension({
  query: {
    ledger: {
      create({ args, query }) {
        if (typeof args.data.last4 === 'string') {
          args.data.last4 = encrypt(args.data.last4) as string;
        }
        return query(args);
      },
      update({ args, query }) {
        if (typeof args.data.last4 === 'string') {
          args.data.last4 = encrypt(args.data.last4) as string;
        }
        return query(args);
      },
    },
  },
});

export const decryptOnRead = Prisma.defineExtension({
  result: {
    ledger: {
      last4: {
        needs: { last4: true },
        compute(ledger) {
          return decrypt(ledger.last4);
        },
      },
    },
    transaction: {
      narration: {
        needs: { narration: true },
        compute(transaction) {
          return decrypt(transaction.narration) ?? transaction.narration;
        },
      },
      merchant: {
        needs: { merchant: true },
        compute(transaction) {
          return decrypt(transaction.merchant);
        },
      },
    },
  },
});
```

Note: `narration` is non-nullable in the schema (`narration String`, not
`String?`), so `decrypt()` should never actually receive `null` for it in
practice — the `?? transaction.narration` fallback exists only so the
TypeScript return type matches the non-nullable field's expected `string`
type (Prisma's generated types require the `result` extension's `compute`
to return the same type as the field), not as real null-handling logic.
`merchant`/`last4` are nullable (`String?`), so their `compute` functions
return `decrypt(...)` directly (which is `string | null`, matching the
field's nullable type).

- [ ] **Step 4: Wire both extensions into `client.ts`**

Modify `node_api/src/prisma/client.ts` — chain the two new extensions after
the existing one (`.$extends()` calls chain; do not replace the existing ID
generation extension):

```typescript
import { PrismaClient } from '@prisma/client';
import { randomBytes } from 'crypto';
import { encryptOnWrite, decryptOnRead } from './encryptionExtension';

const LEDGER_PREFIX: Record<string, string> = {
  BANK_ACCOUNT: 'AC',
  CREDIT_CARD: 'CC',
  LOAN: 'LN',
  WALLET: 'WL',
  CRYPTO: 'CR',
  INVESTMENT: 'INV',
};

function prefixedId(prefix: string): string {
  return `${prefix}-${randomBytes(4).toString('hex').toUpperCase()}`;
}

const prisma = new PrismaClient()
  .$extends({
    query: {
      bank: {
        create({ args, query }) {
          if (!args.data.id) args.data.id = prefixedId('BA');
          return query(args);
        },
      },
      ledger: {
        create({ args, query }) {
          if (!args.data.id) {
            const kind = args.data.kind as string;
            args.data.id = prefixedId(LEDGER_PREFIX[kind] ?? 'LD');
          }
          return query(args);
        },
      },
    },
  })
  .$extends(encryptOnWrite)
  .$extends(decryptOnRead);

export default prisma;
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd node_api && npm test -- src/prisma/encryptionExtension.test.ts`
Expected: 2 tests pass

- [ ] **Step 6: Run the full Node test suite for regressions**

Run: `cd node_api && npm test`
Expected: all tests pass (this task's 2 + Task 2's 4 + the password
feature's 4 from the previous branch)

- [ ] **Step 7: Type-check and manually verify against a running server**

Run: `cd node_api && npx tsc --noEmit`
Expected: no errors

With the local stack running (`docker compose up -d` from the repo root),
create a ledger via GraphQL and confirm it still returns a plaintext
`last4` in the response, exactly as before this change:

```bash
curl -s -X POST http://localhost:4000/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "mutation { createLedger(input: {displayName: \"Manual Test\", kind: BANK_ACCOUNT, last4: \"9999\", bankId: \"<a real bank id>\"}) { id last4 } }"}'
```
Expected: response includes `"last4": "9999"` (plaintext), not ciphertext —
confirming the encryption is fully transparent to GraphQL consumers. Get a
real `bankId` first via `{ banks { id } }` if needed. Clean up the created
test ledger afterward via the `deleteLedger` mutation.

- [ ] **Step 8: Commit**

```bash
git add node_api/src/prisma/encryptionExtension.ts node_api/src/prisma/client.ts \
  node_api/src/prisma/encryptionExtension.test.ts
git commit -m "feat(crypto): encrypt Ledger.last4 and decrypt Transaction fields via Prisma extensions"
```

---

## Task 4: Python — wire `deduplicator.py` (encrypt narration, HMAC fingerprint)

**Files:**
- Modify: `python_service/pipeline/deduplicator.py`
- Test: `python_service/tests/test_deduplicator.py`

**Interfaces:**
- Consumes: `encrypt`, `hmac_fingerprint` from Task 1's
  `crypto/database_encryption.py`.
- Produces: `bulk_insert` and `split_new_and_duplicates` keep their existing
  signatures — this task changes their internal behavior only, no callers
  outside this file need to change.

- [ ] **Step 1: Write the failing tests**

This is an integration test against the real dev Postgres (there is no
existing test file for `deduplicator.py` — it has never been directly
tested before, only exercised indirectly through the full `/import`
endpoint). Create `python_service/tests/test_deduplicator.py`:

```python
import os
import uuid
from datetime import datetime, timezone

import asyncpg
import pytest

from models.schemas import ParsedTransaction
from pipeline.deduplicator import bulk_insert, split_new_and_duplicates

DATABASE_URL = os.environ.get("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/financeos")


@pytest.fixture
async def pool():
    p = await asyncpg.create_pool(DATABASE_URL)
    yield p
    await p.close()


@pytest.fixture
async def test_ledger(pool):
    bank_id = str(uuid.uuid4())
    ledger_id = str(uuid.uuid4())
    async with pool.acquire() as conn:
        await conn.execute(
            'INSERT INTO "Bank" (id, name, code) VALUES ($1, $2, $3)',
            bank_id, "Dedup Test Bank", f"DEDUPTEST{uuid.uuid4().hex[:8]}",
        )
        await conn.execute(
            'INSERT INTO "Ledger" (id, "displayName", kind, "bankId", "updatedAt") VALUES ($1, $2, $3, $4, NOW())',
            ledger_id, "Dedup Test Ledger", "BANK_ACCOUNT", bank_id,
        )
    yield ledger_id
    async with pool.acquire() as conn:
        await conn.execute('DELETE FROM "Transaction" WHERE "ledgerId" = $1', ledger_id)
        await conn.execute('DELETE FROM "Ledger" WHERE id = $1', ledger_id)
        await conn.execute('DELETE FROM "Bank" WHERE id = $1', bank_id)


def make_txn(desc: str, fingerprint: str) -> ParsedTransaction:
    return ParsedTransaction(
        posted_at=datetime(2026, 1, 15, tzinfo=timezone.utc),
        description=desc,
        amount_minor_units=50000,
        currency_code="INR",
        source_fingerprint=fingerprint,
    )


async def test_bulk_insert_stores_encrypted_narration_and_hashed_fingerprint(pool, test_ledger):
    txn = make_txn("SWIGGY BANGALORE", "15/03/24|SWIGGY BANGALORE|50000|0")
    errors = await bulk_insert(pool, test_ledger, [txn])
    assert errors == []

    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            'SELECT narration, "sourceFingerprint" FROM "Transaction" WHERE "ledgerId" = $1',
            test_ledger,
        )
    assert row["narration"] != "SWIGGY BANGALORE"
    assert row["sourceFingerprint"] != "15/03/24|SWIGGY BANGALORE|50000|0"

    from crypto.database_encryption import decrypt
    assert decrypt(row["narration"]) == "SWIGGY BANGALORE"


async def test_split_new_and_duplicates_detects_reimport_after_encryption(pool, test_ledger):
    txn = make_txn("SWIGGY BANGALORE", "15/03/24|SWIGGY BANGALORE|50000|0")
    await bulk_insert(pool, test_ledger, [txn])

    # Re-"import" the exact same transaction — should be detected as a duplicate
    # even though the stored fingerprint is now a hash, not the raw string.
    new_txns, dup_count = await split_new_and_duplicates(pool, test_ledger, [txn])
    assert dup_count == 1
    assert new_txns == []


async def test_split_new_and_duplicates_allows_genuinely_new_transaction(pool, test_ledger):
    txn1 = make_txn("SWIGGY BANGALORE", "15/03/24|SWIGGY BANGALORE|50000|0")
    await bulk_insert(pool, test_ledger, [txn1])

    txn2 = make_txn("ZOMATO DELHI", "16/03/24|ZOMATO DELHI|30000|0")
    new_txns, dup_count = await split_new_and_duplicates(pool, test_ledger, [txn2])
    assert dup_count == 0
    assert len(new_txns) == 1
```

No dependency changes needed here: `pytest-asyncio` (1.4.0) is already
installed and `python_service/pytest.ini` already has `asyncio_mode = auto`
set project-wide — confirmed by running a real async-fixture test against
this exact environment. Plain `@pytest.fixture` on an `async def` generator
(as used above) works correctly under this configuration without needing
`@pytest_asyncio.fixture` or per-test `@pytest.mark.asyncio` markers. This
is the first test file in this project that uses async fixtures, but no
new setup is required.

- [ ] **Step 2: Run tests to verify they fail**

Ensure the local Postgres is running (`docker compose up -d` from the repo
root if not already).

Run: `cd python_service && python -m pytest tests/test_deduplicator.py -v`
Expected: FAIL — the stored `narration`/`sourceFingerprint` are still
plaintext (assertions `!=` fail because they currently DO equal the raw
input), since `deduplicator.py` hasn't been changed yet.

- [ ] **Step 3: Update `deduplicator.py`**

Modify `python_service/pipeline/deduplicator.py`:

```python
import asyncpg
import secrets
from datetime import timezone
from crypto.database_encryption import encrypt, hmac_fingerprint
from models.schemas import ParsedTransaction


def tx_id() -> str:
    return f"TX-{secrets.token_hex(4).upper()}"


async def split_new_and_duplicates(
    pool: asyncpg.Pool,
    ledger_id: str,
    transactions: list[ParsedTransaction],
) -> tuple[list[ParsedTransaction], int]:
    """Return (new_transactions, duplicate_count). Checks existing fingerprint
    hashes in Postgres — sourceFingerprint is stored as an HMAC-SHA256 hash,
    not the raw fingerprint string, so incoming fingerprints are hashed the
    same way before comparison."""
    if not transactions:
        return [], 0

    fingerprint_hashes = [hmac_fingerprint(t.source_fingerprint) for t in transactions]
    existing = await pool.fetch(
        'SELECT "sourceFingerprint" FROM "Transaction" WHERE "ledgerId" = $1 AND "sourceFingerprint" = ANY($2)',
        ledger_id,
        fingerprint_hashes,
    )
    existing_hashes = {row["sourceFingerprint"] for row in existing}
    new_txns = [
        t for t in transactions
        if hmac_fingerprint(t.source_fingerprint) not in existing_hashes
    ]
    return new_txns, len(transactions) - len(new_txns)


async def bulk_insert(pool: asyncpg.Pool, ledger_id: str, transactions: list[ParsedTransaction]) -> list[str]:
    """Insert transactions. Returns list of error strings for failed rows.

    narration is encrypted and sourceFingerprint is hashed (HMAC-SHA256) before
    the INSERT — Postgres never stores either in plaintext. merchant has no
    source anywhere in this pipeline (ParsedTransaction has no merchant field)
    and stays NULL, exactly as before this change.
    """
    if not transactions:
        return []

    errors: list[str] = []
    async with pool.acquire() as conn:
        for t in transactions:
            try:
                # Strip timezone for timestamp without time zone column (convert to UTC first)
                posted_at = t.posted_at
                if posted_at.tzinfo is not None:
                    posted_at = posted_at.astimezone(timezone.utc).replace(tzinfo=None)
                await conn.execute(
                    """
                    INSERT INTO "Transaction" (id, date, narration, "amountMinorUnits", "currencyCode", "ledgerId", category, merchant, "sourceFingerprint", "createdAt")
                    VALUES ($6, $1, $2, $3, $4, $5, NULL, NULL, $7, NOW())
                    ON CONFLICT ("ledgerId", "sourceFingerprint") DO NOTHING
                    """,
                    posted_at,
                    encrypt(t.description),
                    t.amount_minor_units,
                    t.currency_code or "INR",
                    ledger_id,
                    tx_id(),
                    hmac_fingerprint(t.source_fingerprint),
                )
            except Exception as e:
                errors.append(f"Row {t.statement_row_index}: {e}")
    return errors
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd python_service && python -m pytest tests/test_deduplicator.py -v`
Expected: 3 passed

- [ ] **Step 5: Run the full Python test suite for regressions**

Run: `cd python_service && python -m pytest tests/ -q --deselect tests/test_analytics.py::test_total_spend --deselect tests/test_analytics.py::test_total_income --deselect tests/test_analytics.py::test_net_flow --deselect tests/test_analytics.py::test_by_category --deselect tests/test_analytics.py::test_by_month`
Expected: all pass (the 5 deselected `test_analytics.py` failures are
pre-existing and unrelated — confirmed present on `main` before any of this
plan's changes, from an earlier unrelated migration; this repo has never
touched `analytics/` in this plan)

- [ ] **Step 6: Manual verification against the live import endpoint**

With the local stack running, run a real import through the full pipeline
(the same `/parse` → `/import` flow the client uses) and confirm:
1. The `Transaction` row's `narration` column in Postgres is ciphertext
   (query directly: `docker compose exec postgres psql -U postgres -d
   financeos -c 'SELECT narration FROM "Transaction" LIMIT 1;'`)
2. The GraphQL `transactions` query still returns the plaintext narration
   (Task 3's `decryptOnRead` extension handles this)
3. Re-uploading the exact same statement file is still correctly rejected
   as a duplicate (check the `uploadStatement` mutation's returned
   `duplicates` count on the second upload)

- [ ] **Step 7: Commit**

```bash
git add python_service/pipeline/deduplicator.py python_service/tests/test_deduplicator.py \
  python_service/requirements.txt
git commit -m "feat(crypto): encrypt narration and hash sourceFingerprint in import pipeline"
```

---
