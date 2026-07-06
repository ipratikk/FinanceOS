# Password-Protected PDF Import — Design

## Context

This is the second of three specs from the import-flow conversation that produced
`2026-07-05-single-screen-import-flow-design.md` (UI flow → **password-protected
PDFs** → Postgres column encryption). The single-screen import flow shipped in
FINOS-114 already has a forward-referencing "Password Protected?" trust banner and
a built-but-unwired `PasswordPromptSheet.swift` (with a `SheetRoute.passwordPrompt`
case that nothing renders) — this spec connects that scaffold to a real backend.

Indian bank statements are commonly password-protected PDFs (DOB/PAN-derived
passwords). The backend's 4 existing PDF parsers (`hdfc_bank_pdf`, `hdfc_card_pdf`,
`icici_bank_pdf`, `scapia_card`) all use `pdfplumber`, which forwards a `password`
kwarg to `pdfminer` — today none of them ever supply one, so any encrypted PDF
fails PDF parser `detect()` (which swallows the resulting exception) and falls
through to a generic "Unrecognised statement format" error.

**Explicitly out of scope:** XLSX. The backend has zero XLSX parsing today (no
`openpyxl`/`msoffcrypto` dependency, no parser file, nothing in `detector.py`) —
building XLSX ingestion is a real, independent feature unrelated to encryption
(unencrypted XLSX statements can't be imported either) and is deferred to its own
future spec. XLSX password support becomes a follow-up to *that* spec, once XLSX
ingestion exists. CSV/TXT are plain text and have no native password/encryption
concept; the only real-world equivalent (a password-protected ZIP email
attachment) is a structurally different feature, also out of scope.

## Architecture

**Reactive, backend-driven detection — no client-side pre-check.** The client
does not try to detect encryption itself (no PDFKit lock-check); it always calls
`previewStatement` first, and the backend reports back if a password is needed.
This keeps all format-specific logic backend-owned (consistent with
`docs/ARCHITECTURE.md`'s parsing-is-backend-only rule) and generalizes to future
formats without new client code.

**The password itself never crosses the wire in plaintext**, independent of
transport (TLS/HTTPS). This repo's transit-encryption work
(`DATABASE_ENCRYPTION_KEY`-style setup) is explicitly "local dev only for now" —
there is currently no TLS between the Swift client and `node_api` in dev, so
relying on transport encryption alone for a credential is not acceptable here.
Instead, the password gets its own application-layer encryption:

- **One-time backend setup:** generate a permanent P-256 (NIST secp256r1)
  keypair. The private key lives in `node_api`'s `IMPORT_PASSWORD_PRIVATE_KEY`
  env var (same env-var-secret pattern as `DATABASE_ENCRYPTION_KEY`, but a
  **separate key** — key separation between "data at rest" and "credential in
  transit" purposes). The public key is safe to embed directly in the Swift
  client as a source constant — it's public by definition, there is nothing to
  protect by keeping it secret.
- **Per password, client-side:** generate a fresh ephemeral P-256 keypair, do
  ECDH with the backend's embedded public key, derive a 256-bit AES key via
  HKDF-SHA256, seal the plaintext password with AES-256-GCM (`CryptoKit`,
  built into every Apple platform — no new dependency, no bundle-size cost).
  Send `{ephemeralPublicKey, ciphertext}` (both base64) as the mutation's
  password argument. A fresh ephemeral keypair is generated for every seal
  call — nothing is reused across requests.
- **Backend-side:** `node_api` reverses this using Node's built-in `crypto`
  module (`createECDH('prime256v1')` + `crypto.hkdfSync`) — no new npm
  dependency either. It recovers the plaintext password and forwards *that* to
  `python_service` over the existing internal (non-internet-facing) call, the
  same trust boundary the raw file bytes and `ledgerId` already cross today.
- **No key rotation in v1.** One static keypair; client and backend are
  updated together by the same person (personal, single-user app). Documented
  limitation, not built.
- **HKDF parameters are fixed and must match exactly on both sides:** empty
  salt, and `info` = the fixed UTF-8 string `"financeos-import-password-v1"`,
  output length 32 bytes (AES-256 key). `CryptoKit`'s
  `SharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self, salt: Data(),
  sharedInfo: Data("financeos-import-password-v1".utf8), outputByteCount: 32)`
  and Node's `crypto.hkdfSync('sha256', sharedSecret, Buffer.alloc(0),
  Buffer.from("financeos-import-password-v1"), 32)` must produce identical
  keys for the same ECDH shared secret — this exact pairing is what the
  cross-language fixture test (see Testing) verifies. The wire format for the
  sealed payload is `CryptoKit`'s `AES.GCM.SealedBox.combined` layout:
  `nonce (12 bytes) ‖ ciphertext ‖ tag (16 bytes)`, base64-encoded as the
  `ciphertext` field; Node's decrypt must slice those three regions in that
  order before calling `createDecipheriv('aes-256-gcm', key, nonce)` +
  `setAuthTag(tag)`.

`pdfminer` raises the same `PDFPasswordIncorrect` exception whether no password
was supplied or the wrong one was — there is exactly one signal to handle, not
two ("needs a password" and "wrong password" are indistinguishable
server-side). The client tracks, per file, whether this is the first attempt or
a retry, and only shows "incorrect password" copy on a retry.

## Components

**Client (Swift) — new**, both in `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/Services/`:
- `ImportPasswordCrypto.swift` — `seal(_ password: String) throws -> (ephemeralPublicKey: String, ciphertext: String)` using `CryptoKit` against an embedded backend public-key constant.
- `ImportPasswordStore.swift` — Keychain wrapper behind a small protocol (for test injection, matching the existing `StatementParsingProtocol` pattern): `password(for ledgerId: UUID) -> String?`, `save(_ password: String, for ledgerId: UUID)`, via `Security` (`SecItemAdd`/`SecItemCopyMatching`/`SecItemUpdate`), a dedicated service identifier (e.g. `"com.financeos.import.pdfpassword"`).

**Client — modified:**
- `ImportSession.swift` — add `filePasswords: [URL: String]`, remembering a resolved plaintext password per file for the rest of that file's session so `uploadStatement` doesn't re-prompt after `previewStatement` already succeeded.
- `ImportViewModel.swift` / `ImportViewModelStateManagement.swift` — `parseFiles()`'s existing sequential per-file loop gains: call preview → if `passwordRequired`, resolve (Keychain via the pre-known target ledger id, else prompt) → seal → retry → on repeat `passwordRequired`, re-prompt with `isPasswordInvalid: true`.
- `ImportFileParser.swift` — threads the sealed password through `PreviewStatementMutation`/`UploadStatementMutation`; surfaces `passwordRequired` back to the view model.
- `ImportView.swift` — local `@State` + `.sheet(item:)` for `PasswordPromptSheet`, following `ImportTargetSection`'s existing `TargetCreationState`/`sheetCreationItem` pattern. The dead `SheetRoute.passwordPrompt` case is deleted (nothing renders it today, and it doesn't fit this pattern — sheets driven by per-instance callback data use local `@State` in this codebase, not the global `SheetRoute` switch).
- `Apps/FinanceOSMac/GraphQL/Operations/Mutations.graphql` + regenerated codegen (`Scripts/codegen.sh`) for the new `password` argument and `passwordRequired` field.

**Backend — new/modified:**
- `node_api/src/schema/typedefs.graphql` — `input EncryptedPassword { ephemeralPublicKey: String!, ciphertext: String! }`; `password: EncryptedPassword` optional arg on `previewStatement` and `uploadStatement`; `passwordRequired: Boolean!` added to `StatementPreview`.
- `node_api/src/services/passwordCrypto.ts` (new) — `decryptPassword(encrypted: { ephemeralPublicKey: string; ciphertext: string }): string`, loads `IMPORT_PASSWORD_PRIVATE_KEY` at module load, ECDH + HKDF-SHA256 + AES-256-GCM decrypt via Node's built-in `crypto`.
- `node_api/src/services/python.ts` — `parseFile(...)` gains an optional `password?: string` param, forwarded as a form field; `ParseResponse` gains `password_required: boolean`.
- `node_api/src/resolvers/preview.ts` / `upload.ts` — decrypt the incoming `password` (if present) via `passwordCrypto.ts`, thread the plaintext to `parseFile()`. `preview.ts` maps `parsed.password_required` straight to the `passwordRequired` field. `upload.ts` throws a GraphQL error if `parsed.password_required` comes back true (should not normally happen — see Error Handling).
- `python_service/main.py` — `/parse` gains `password: str | None = Form(default=None)`; catches `pdfminer.pdfdocument.PDFPasswordIncorrect` and returns `{"password_required": true, ...}` (other fields default/empty) instead of raising.
- `python_service/parsers/base.py` — `BaseBankParser.detect()`/`.parse()` gain an optional `password: str | None = None` parameter.
- `python_service/parsers/detector.py` — threads `password` through to each parser's `.detect()`; catches `PDFPasswordIncorrect` distinctly from the existing generic `except Exception: continue`, so "at least one PDF parser needs a password" is distinguishable from "no parser recognizes this format at all."
- The 4 PDF parsers (`hdfc_bank_pdf.py`, `hdfc_card_pdf.py`, `icici_bank_pdf.py`, `scapia_card.py`) — pass `password=password` into their `pdfplumber.open()` calls.
- The remaining ~9 CSV/TXT parsers — mechanical signature update to accept (and ignore) the new `password` parameter, so `detector.py`'s uniform call sites work across all parsers.
- One-time setup: a documented script/command to generate the P-256 keypair once. Private half goes into `.env` (gitignored); public half becomes the Swift-side constant. Documented in `financeos-backend`'s README.

## Data Flow

1. User drops a file. `parseFiles()` calls `previewStatement(file:, password: nil)`.
2. **Not encrypted:** `passwordRequired: false` — proceeds exactly as today, no behavior change.
3. **Encrypted, no pre-known target:** `passwordRequired: true` → `ImportPasswordStore` has no ledger id to check yet → show `PasswordPromptSheet` → user enters password → `ImportPasswordCrypto.seal()` → retry `previewStatement` with the sealed password.
4. **Encrypted, pre-known target** (entry from a Card/Account's "Import statement" button — `navigator.pendingImportTarget` already set): same as #3, but check `ImportPasswordStore.password(for: ledgerId)` first. If found, seal and retry silently — no prompt shown at all.
5. **Wrong password:** the retry from #3/#4 comes back `passwordRequired: true` again → re-show the sheet with `isPasswordInvalid: true`. Loop until correct or the user cancels.
6. On success, if "Save to Keychain" was checked in the sheet, `ImportPasswordStore.save(password, for:)` — keyed by the target ledger id once it's resolved (right after this file's preview succeeds, via auto-match or manual pick).
7. `importTransactions()` re-seals (fresh ephemeral keypair, never reused) and re-sends the same plaintext password from `importSession.filePasswords[fileURL]` on `uploadStatement`. Expected to succeed, since it already worked at preview time.

## Error Handling

- **Wrong/missing password:** the reactive retry loop above (steps 3–5) — the expected, common case, not an error banner.
- **User cancels the password prompt:** that file drops out of the batch and the rest continue; if it's the only file, the flow returns to `.idle` (matches existing abort behavior in `parseFiles()`).
- **Correct password, but still unparseable** (corrupted PDF, or a bank format no parser recognizes): independent of password success — `pdfplumber` opens fine, `detect_parser` just finds no match, falls through to the existing "Unrecognised statement format" 422. Not conflated with a password failure.
- **Crypto/decryption failure server-side** (malformed envelope, transport corruption, or a stale client embedding a public key that no longer matches a rotated private key): `passwordCrypto.ts` throws — surfaced as a generic GraphQL error, **not** `passwordRequired`, so the client shows a plain error banner instead of looping the password-retry UI against a bug re-prompting can't fix.
- **Keychain read/write failure:** non-fatal — log and fall back to prompting normally. Never blocks the import.
- **`uploadStatement` password failure:** hard error via the existing generic `errorMessage`/phase-revert-to-`.readyToImport` path. Expected to be rare (same password already worked once, at preview time).

## Testing

**Backend (Python):** parser tests confirming the 4 PDF parsers thread `password` into `pdfplumber.open()`; a `detect_parser` test distinguishing `PDFPasswordIncorrect` from "no parser recognizes this format"; a `/parse` endpoint test (FastAPI `TestClient`) asserting the `password_required` response shape against an encrypted fixture PDF.

**Backend (Node):** unit tests for `passwordCrypto.ts`'s decrypt logic, plus one **fixture-based cross-language interop test**: a single committed test vector (fixed test-only private key, fixed sealed ciphertext, expected plaintext) verified independently by a Node test (decrypts the fixture) and a Swift test (decrypts the same fixture via `CryptoKit`). A self-consistency test on either language alone would not catch a real cross-language byte-format mismatch (nonce/tag layout, HKDF salt/info strings) — this fixture is the one piece of the design that needs it explicitly.

**Client (Swift):** `ImportPasswordCrypto` self-consistency test (seal with a test keypair, decrypt with `CryptoKit` itself); `ImportPasswordStore` Keychain round-trip test (isolated test-only service identifier, not the real app's entries); an `ImportViewModelStateManagement`-style regression test using the existing injectable `StatementParsingProtocol` seam (fake parser returns `passwordRequired` then success; assert the retry flow, and that a pre-known ledger id checks Keychain first — requires `ImportPasswordStore` to be protocol-ized/injectable the same way); new snapshot tests for `PasswordPromptSheet` (currently zero coverage — both `isPasswordInvalid: false`/`true` states).

**Manual:** a real password-protected HDFC/ICICI PDF sample, full drop → prompt → unlock → import, plus the Keychain-remembered path on a second import from the same ledger.
