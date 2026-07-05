# Password-Protected PDF Import Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users import password-protected PDF bank/card statements, with the
password encrypted client-side before it ever reaches the network.

**Architecture:** Reactive backend-driven detection (`previewStatement` returns
`passwordRequired: true` for encrypted PDFs; no client-side lock pre-check).
The password is sealed client-side with an ephemeral-ECDH + HKDF-SHA256 +
AES-256-GCM "sealed box" against a permanent backend public key, decrypted
server-side with the matching private key, and threaded into the 4 existing
`pdfplumber`-based PDF parsers.

**Tech Stack:** Swift `CryptoKit` (client crypto, built-in), `Security`
framework (Keychain, built-in), Node's built-in `crypto` module (server
decrypt, no new npm dependency), Python `pdfplumber`/`pdfminer` (already a
dependency), `pypdf` (new, test-fixture generation only), Node's built-in
`node:test` runner (new test infra for `node_api`, zero new dependencies).

This plan spans two repositories:
- **`FinanceOS-Backend`** (Tasks 1–4) — ships and deploys first.
- **`FinanceOS`** (Tasks 5–8, this repo) — depends on Tasks 1–4 being live
  locally before Task 8's GraphQL codegen step will produce correct types.

Design spec: `docs/superpowers/specs/2026-07-06-password-protected-pdf-import-design.md`.

## Global Constraints

- Explicitly out of scope: XLSX (no parser exists in the backend at all yet —
  separate future spec) and CSV/TXT (no native password concept).
- The plaintext password must never cross the network — only the sealed
  `{ephemeralPublicKey, ciphertext}` envelope does.
- HKDF parameters are fixed and must match exactly on both sides: empty salt,
  `info` = UTF-8 string `"financeos-import-password-v1"`, 32-byte output.
- Sealed payload wire format is `CryptoKit`'s `AES.GCM.SealedBox.combined`
  layout: `nonce (12 bytes) ‖ ciphertext ‖ tag (16 bytes)`, base64-encoded.
- `pdfminer.pdfdocument.PDFPasswordIncorrect` is the single signal for both
  "no password given" and "wrong password given" — there is exactly one
  outcome to handle server-side, not two.
- No key rotation in v1 — one static P-256 keypair, documented limitation.
- No third-party crypto library on either side — `CryptoKit` and Node's
  built-in `crypto` only.

---

## File Structure

**`FinanceOS-Backend/python_service/` (Tasks 1–2):**
- Modify: `parsers/base.py`, `parsers/detector.py`
- Modify: `parsers/hdfc_bank_pdf.py`, `parsers/hdfc_card_pdf.py`, `parsers/icici_bank_pdf.py`, `parsers/scapia_card.py` (the 4 PDF parsers — actually thread the password into `pdfplumber.open()`)
- Modify: `parsers/hdfc_bank_txt.py`, `parsers/hdfc_card.py`, `parsers/icici_bank.py`, `parsers/icici_card.py`, `parsers/amex_card.py`, `parsers/axis_bank.py`, `parsers/axis_card.py`, `parsers/sbi_card.py`, `parsers/sbi_bank.py` (9 CSV/TXT parsers — mechanical signature update only)
- Create: `parse_service.py` (extracts `/parse`'s response-building logic into a plain, DB-free function so it's unit-testable without a live Postgres — `main.py`'s lifespan connects to Postgres on startup, which `TestClient` would otherwise trigger)
- Modify: `main.py` (`/parse` becomes a thin wrapper around `parse_service.build_parse_response`)
- Modify: `requirements.txt` (add `pypdf`, test-fixture generation only)
- Test: `tests/test_password_protected.py` (new), `tests/fixtures/hdfc_bank_pdf_locked.pdf` (new, generated)

**`FinanceOS-Backend/node_api/` (Tasks 3–4):**
- Create: `src/services/passwordCrypto.ts`
- Test: `src/services/passwordCrypto.test.ts` (new — also establishes `node_api`'s first test infrastructure)
- Modify: `src/services/python.ts`, `src/schema/typedefs.graphql`, `src/resolvers/preview.ts`, `src/resolvers/upload.ts`, `package.json` (add `test` script)
- Create: `scripts/generate-import-password-keypair.js` (one-time setup)

**`FinanceOS/Apps/FinanceOSMac/` (Tasks 5–8, this repo):**
- Create: `FinanceOSMac/Presentation/Import/Services/ImportPasswordCrypto.swift`
- Create: `FinanceOSMac/Presentation/Import/Services/ImportPasswordStore.swift`
- Modify: `FinanceOSMac/Presentation/Import/ImportSession.swift`
- Modify: `FinanceOSMac/Presentation/Import/ImportViewModel.swift`, `ImportViewModelStateManagement.swift`
- Modify: `FinanceOSMac/Presentation/Import/Services/ImportFileParser.swift`
- Modify: `FinanceOSMac/Presentation/Import/ImportView.swift`
- Modify: `FinanceOSMac/Presentation/Navigation/SheetRoute.swift` (delete `.passwordPrompt`)
- Modify: `GraphQL/Operations/Mutations.graphql` + regenerated codegen output
- Test: `FinanceOSMacSnapshotTests/Flows/ImportPasswordCryptoTests.swift`, `ImportPasswordStoreTests.swift`, `ImportViewModelPasswordTests.swift`, `PasswordPromptSheetSnapshotTests.swift` (all new)

---

## Task 1: Python — thread `password` through the parser layer

**Repo:** `FinanceOS-Backend`

**Files:**
- Modify: `python_service/parsers/base.py`
- Modify: `python_service/parsers/detector.py`
- Modify: `python_service/parsers/hdfc_bank_pdf.py`
- Modify: `python_service/parsers/hdfc_card_pdf.py`
- Modify: `python_service/parsers/icici_bank_pdf.py`
- Modify: `python_service/parsers/scapia_card.py`
- Modify: `python_service/parsers/hdfc_bank_txt.py`, `hdfc_card.py`, `icici_bank.py`, `icici_card.py`, `amex_card.py`, `axis_bank.py`, `axis_card.py`, `sbi_card.py`, `sbi_bank.py`
- Modify: `python_service/requirements.txt`
- Test: `python_service/tests/test_password_protected.py`
- Test fixture (generated by this task): `python_service/tests/fixtures/hdfc_bank_pdf_locked.pdf`

**Interfaces:**
- Produces: `BaseBankParser.detect(self, content: bytes, password: str | None = None) -> bool`, `BaseBankParser.parse(self, content: bytes, password: str | None = None) -> list[ParsedTransaction]`, `detect_parser(content: bytes, bank_code: str | None = None, password: str | None = None) -> BaseBankParser | None` (raises `pdfminer.pdfdocument.PDFPasswordIncorrect` if at least one PDF parser needed a password it didn't get/got wrong).

- [ ] **Step 1: Add `pypdf` for fixture generation**

Add to `python_service/requirements.txt`:

```
pypdf==4.2.0
```

Run: `pip install -r python_service/requirements.txt`

- [ ] **Step 2: Generate the encrypted PDF test fixture**

There is no existing password-protected PDF fixture in this repo. Generate
one by encrypting the existing unlocked fixture used by `test_hdfc_bank_txt.py`'s
neighbor PDF tests — actually the existing HDFC bank PDF parser has no fixture
file at all (`test_detector.py` only exercises CSV/TXT fixtures). Create a
minimal one-page PDF with `pypdf` containing the exact header text
`HDFCBankPDFParser.detect()` looks for, then encrypt it. Run this one-off
script from `python_service/`:

```python
# scripts/generate_locked_pdf_fixture.py — run once, not part of the app
from pypdf import PdfWriter
from pypdf.generic import RectangleObject

writer = PdfWriter()
writer.add_blank_page(width=612, height=792)
page = writer.pages[0]
writer.add_metadata({"/Title": "Test Statement"})

# pypdf's add_blank_page + a minimal text-drawing helper isn't built in;
# use reportlab-free approach: write literal content stream text.
content = b"BT /F1 12 Tf 72 700 Td (WithdrawalAmt. DepositAmt. Narration) Tj ET"
from pypdf.generic import DecodedStreamObject, NameObject
stream = DecodedStreamObject()
stream.set_data(content)
page[NameObject("/Contents")] = writer._add_object(stream)
from pypdf.generic import DictionaryObject
font = DictionaryObject()
font[NameObject("/Type")] = NameObject("/Font")
font[NameObject("/Subtype")] = NameObject("/Type1")
font[NameObject("/BaseFont")] = NameObject("/Helvetica")
font_ref = writer._add_object(font)
resources = DictionaryObject()
fonts = DictionaryObject()
fonts[NameObject("/F1")] = font_ref
resources[NameObject("/Font")] = fonts
page[NameObject("/Resources")] = resources

writer.encrypt(user_password="secret123", owner_password="secret123")

with open("tests/fixtures/hdfc_bank_pdf_locked.pdf", "wb") as f:
    writer.write(f)

print("wrote tests/fixtures/hdfc_bank_pdf_locked.pdf")
```

Run: `cd python_service && python scripts/generate_locked_pdf_fixture.py`
Expected: `wrote tests/fixtures/hdfc_bank_pdf_locked.pdf`

Verify it's actually encrypted and `pdfplumber` needs the password:

```bash
python3 -c "
import pdfplumber
try:
    pdfplumber.open('tests/fixtures/hdfc_bank_pdf_locked.pdf')
    print('FAIL: opened without password')
except Exception as e:
    print('OK, raised:', type(e).__name__)
"
```

Expected: `OK, raised: PDFPasswordIncorrect` (or a wrapping exception —
if pdfplumber raises something else, note the exact exception name for
Step 5's import).

Delete the one-off script after the fixture file exists (it's not part of
the app; the generated `.pdf` fixture is what gets committed):
`rm scripts/generate_locked_pdf_fixture.py`

- [ ] **Step 3: Write the failing tests**

Create `python_service/tests/test_password_protected.py`:

```python
import pathlib
import pytest
from pdfminer.pdfdocument import PDFPasswordIncorrect
from parsers.base import BaseBankParser
from parsers.detector import detect_parser
from parsers.hdfc_bank_pdf import HDFCBankPDFParser

FIXTURES = pathlib.Path(__file__).parent / "fixtures"
LOCKED_PDF = (FIXTURES / "hdfc_bank_pdf_locked.pdf").read_bytes()


def test_detect_raises_password_incorrect_with_no_password():
    with pytest.raises(PDFPasswordIncorrect):
        HDFCBankPDFParser().detect(LOCKED_PDF)


def test_detect_raises_password_incorrect_with_wrong_password():
    with pytest.raises(PDFPasswordIncorrect):
        HDFCBankPDFParser().detect(LOCKED_PDF, password="wrongpassword")


def test_detect_succeeds_with_correct_password():
    assert HDFCBankPDFParser().detect(LOCKED_PDF, password="secret123") is True


def test_detector_raises_password_incorrect_for_locked_pdf():
    with pytest.raises(PDFPasswordIncorrect):
        detect_parser(LOCKED_PDF)


def test_detector_finds_parser_with_correct_password():
    parser = detect_parser(LOCKED_PDF, password="secret123")
    assert isinstance(parser, HDFCBankPDFParser)


def test_csv_parsers_ignore_password_param():
    # Mechanical signature check: every parser accepts (and can ignore) `password`.
    content = (FIXTURES / "hdfc_card.csv").read_bytes()
    from parsers.hdfc_card import HDFCCardParser
    assert HDFCCardParser().detect(content, password="irrelevant") is True
```

- [ ] **Step 4: Run tests to verify they fail**

Run: `cd python_service && python -m pytest tests/test_password_protected.py -v`
Expected: FAIL — `TypeError: detect() got an unexpected keyword argument 'password'`

- [ ] **Step 5: Update `base.py`**

Modify `python_service/parsers/base.py`:

```python
from abc import ABC, abstractmethod
from models.schemas import ParsedTransaction


class BaseBankParser(ABC):
    bank_code: str  # unique identifier, e.g. "hdfc_card"

    @abstractmethod
    def detect(self, content: bytes, password: str | None = None) -> bool:
        """Return True if this parser can handle the given file content.

        Raises pdfminer.pdfdocument.PDFPasswordIncorrect if the content is an
        encrypted PDF and `password` is missing or wrong.
        """

    @abstractmethod
    def parse(self, content: bytes, password: str | None = None) -> list[ParsedTransaction]:
        """Parse file content and return list of transactions."""

    def extract_last4(self, content: bytes) -> str | None:
        """Return the last 4 digits of the card/account number, if present in the statement."""
        return None
```

- [ ] **Step 6: Update the 4 PDF parsers**

Modify `python_service/parsers/hdfc_bank_pdf.py` — change the `detect`
method's signature and body, and the `parse` method's signature (body
unchanged except the `pdfplumber.open()` call):

```python
import io
import re
from collections import defaultdict
from pdfminer.pdfdocument import PDFPasswordIncorrect
from models.schemas import ParsedTransaction
from parsers.base import BaseBankParser
from parsers.utils import parse_amount, parse_date

_DATE_RE = re.compile(r'^\d{2}/\d{2}/\d{2}$')
_REF_RE = re.compile(r'^\d{8,}$')


class HDFCBankPDFParser(BaseBankParser):
    bank_code = "hdfc_bank_pdf"

    def detect(self, content: bytes, password: str | None = None) -> bool:
        if content[:4] != b'%PDF':
            return False
        try:
            import pdfplumber
            with pdfplumber.open(io.BytesIO(content), password=password or "") as pdf:
                text = (pdf.pages[0].extract_text() or "") if pdf.pages else ""
            return 'WithdrawalAmt.' in text and 'DepositAmt.' in text and 'Narration' in text
        except PDFPasswordIncorrect:
            raise
        except Exception:
            return False

    def parse(self, content: bytes, password: str | None = None) -> list[ParsedTransaction]:
        import pdfplumber

        results: list[ParsedTransaction] = []
        row_idx = 0

        # Column positions from the first page that has the header; reused for all subsequent pages
        withdrawal_x = withdrawal_x1 = deposit_x = deposit_x1 = closing_x = None
        wd_mid = dc_mid = None

        with pdfplumber.open(io.BytesIO(content), password=password or "") as pdf:
            for page in pdf.pages:
                words = page.extract_words()

                # Update column positions if header found on this page
                for w in words:
                    if w['text'] == 'WithdrawalAmt.':
                        withdrawal_x = w['x0']
                        withdrawal_x1 = w['x1']
                    elif w['text'] == 'DepositAmt.' and deposit_x is None:
                        deposit_x = w['x0']
                        deposit_x1 = w['x1']
                    elif w['text'] == 'ClosingBalance' and closing_x is None:
                        closing_x = w['x0']

                if withdrawal_x is None:
                    continue  # haven't found header on any page yet

                if wd_mid is None:
                    # Use right edge of WithdrawalAmt. header to avoid misclassifying
                    # wide withdrawal amounts that extend past the column x0 midpoint
                    wd_mid = (withdrawal_x1 + deposit_x) / 2 if (withdrawal_x1 and deposit_x) else withdrawal_x + 60
                    dc_mid = (deposit_x1 + closing_x) / 2 if (deposit_x1 and closing_x) else withdrawal_x + 100

                # All words on page (account info rows don't have date-pattern at x0<70)
                tx_words = words

                # Group by row (round top to nearest pixel)
                buckets: dict[int, list] = defaultdict(list)
                for w in tx_words:
                    buckets[round(w['top'])].append(w)

                current: dict | None = None

                def _flush(txn: dict | None) -> ParsedTransaction | None:
                    if txn is None:
                        return None
                    date = parse_date(txn['date'], '%d/%m/%y', '%d/%m/%Y')
                    if not date:
                        return None
                    w_amt = txn.get('withdrawal')
                    d_amt = txn.get('deposit')
                    if w_amt is not None:
                        amount = w_amt
                    elif d_amt is not None:
                        amount = -d_amt
                    else:
                        return None
                    desc = ' '.join(txn['narration'])
                    fp = f"{txn['date']}|{''.join(desc.split())}|{w_amt or 0}|{d_amt or 0}"
                    return ParsedTransaction(
                        posted_at=date,
                        description=desc,
                        amount_minor_units=amount,
                        currency_code='INR',
                        source_fingerprint=fp,
                        closing_balance_minor_units=txn.get('closing'),
                        statement_row_index=txn['idx'],
                    )

                for bucket_y in sorted(buckets):
                    row = sorted(buckets[bucket_y], key=lambda w: w['x0'])
                    leftmost = row[0]

                    if _DATE_RE.match(leftmost['text']) and leftmost['x0'] < 70:
                        # New transaction row
                        if current:
                            t = _flush(current)
                            if t:
                                results.append(t)
                                row_idx += 1

                        current = {
                            'date': leftmost['text'],
                            'narration': [],
                            'withdrawal': None,
                            'deposit': None,
                            'closing': None,
                            'idx': row_idx,
                        }

                        for w in row[1:]:
                            x = w['x0']
                            if closing_x and x >= dc_mid:
                                current['closing'] = parse_amount(w['text'])
                            elif x >= wd_mid:
                                current['deposit'] = parse_amount(w['text'])
                            elif x >= withdrawal_x - 10:
                                current['withdrawal'] = parse_amount(w['text'])
                            elif x < 265 and not _DATE_RE.match(w['text']) and not _REF_RE.match(w['text']):
                                current['narration'].append(w['text'])
                    else:
                        # Continuation row — add narration-column words to current transaction
                        if current:
                            for w in row:
                                if 70 <= w['x0'] < 265 and not _REF_RE.match(w['text']):
                                    current['narration'].append(w['text'])

                # Flush last transaction on page
                if current:
                    t = _flush(current)
                    if t:
                        results.append(t)
                        row_idx += 1
                    current = None

        return results
```

Apply the same two changes (import `PDFPasswordIncorrect`, `detect` signature
+ try/except + `password=password or ""` on the `pdfplumber.open()` call,
`parse` signature + `password=password or ""` on its `pdfplumber.open()`
call) to the other 3 PDF parsers:

`python_service/parsers/hdfc_card_pdf.py` — add the import, change:
```python
    def detect(self, content: bytes, password: str | None = None) -> bool:
        if content[:4] != b'%PDF':
            return False
        try:
            import pdfplumber
            with pdfplumber.open(io.BytesIO(content), password=password or "") as pdf:
                text = (pdf.pages[0].extract_text() or "") if pdf.pages else ""
            return (
                ('HDFC' in text or 'Hdfc' in text)
                and ('Card No' in text or 'Credit Card No.' in text)
            )
        except PDFPasswordIncorrect:
            raise
        except Exception:
            return False
```
and:
```python
    def parse(self, content: bytes, password: str | None = None) -> list[ParsedTransaction]:
        import pdfplumber
        pages_text: list[str] = []
        with pdfplumber.open(io.BytesIO(content), password=password or "") as pdf:
            for page in pdf.pages:
                t = page.extract_text()
                if t:
                    pages_text.append(t)
        full_text = '\n'.join(pages_text)
        # ... rest unchanged
```
(leave the `_parse_v1`/`_parse_v2` dispatch logic below unchanged).

`python_service/parsers/icici_bank_pdf.py` — same pattern:
```python
    def detect(self, content: bytes, password: str | None = None) -> bool:
        if content[:4] != b'%PDF':
            return False
        try:
            import pdfplumber
            with pdfplumber.open(io.BytesIO(content), password=password or "") as pdf:
                text = (pdf.pages[0].extract_text() or "") if pdf.pages else ""
            return (
                'ICICI' in text
                and 'Saving Account' in text
                and 'Withdrawal' in text
                and 'Deposit' in text
            )
        except PDFPasswordIncorrect:
            raise
        except Exception:
            return False

    def parse(self, content: bytes, password: str | None = None) -> list[ParsedTransaction]:
        import pdfplumber
        results: list[ParsedTransaction] = []
        with pdfplumber.open(io.BytesIO(content), password=password or "") as pdf:
            # ... rest of body unchanged
```
(add `from pdfminer.pdfdocument import PDFPasswordIncorrect` to the imports).

`python_service/parsers/scapia_card.py` — same pattern:
```python
    def detect(self, content: bytes, password: str | None = None) -> bool:
        if content[:4] != b'%PDF':
            return False
        try:
            import pdfplumber
            with pdfplumber.open(io.BytesIO(content), password=password or "") as pdf:
                text = (pdf.pages[0].extract_text() or "") if pdf.pages else ""
            return 'ScapiaCoins' in text or ('Scapia' in text and 'BillingCycle' in text)
        except PDFPasswordIncorrect:
            raise
        except Exception:
            return False

    def parse(self, content: bytes, password: str | None = None) -> list[ParsedTransaction]:
        import pdfplumber
        results: list[ParsedTransaction] = []
        in_tx = False
        with pdfplumber.open(io.BytesIO(content), password=password or "") as pdf:
            # ... rest of body unchanged
```
(add `from pdfminer.pdfdocument import PDFPasswordIncorrect` to the imports).

- [ ] **Step 7: Mechanical signature update on the 9 CSV/TXT parsers**

In each of `hdfc_bank_txt.py`, `hdfc_card.py`, `icici_bank.py`, `icici_card.py`,
`amex_card.py`, `axis_bank.py`, `axis_card.py`, `sbi_card.py`, `sbi_bank.py`,
change:
```python
    def detect(self, content: bytes) -> bool:
```
to:
```python
    def detect(self, content: bytes, password: str | None = None) -> bool:
```
and:
```python
    def parse(self, content: bytes) -> list[ParsedTransaction]:
```
to:
```python
    def parse(self, content: bytes, password: str | None = None) -> list[ParsedTransaction]:
```
The parameter is unused in all 9 — no other body changes.

- [ ] **Step 8: Update `detector.py`**

Modify `python_service/parsers/detector.py`:

```python
from pdfminer.pdfdocument import PDFPasswordIncorrect
from parsers.base import BaseBankParser
from parsers.hdfc_card import HDFCCardParser
from parsers.hdfc_card_pdf import HDFCCardPDFParser
from parsers.hdfc_bank_txt import HDFCBankTXTParser
from parsers.hdfc_bank_pdf import HDFCBankPDFParser
from parsers.icici_card import ICICICardParser
from parsers.icici_bank import ICICIBankParser
from parsers.icici_bank_pdf import ICICIBankPDFParser
from parsers.amex_card import AmexCardParser
from parsers.scapia_card import ScapiaCardParser
from parsers.axis_bank import AxisBankParser
from parsers.axis_card import AxisCardParser
from parsers.sbi_card import SBICardParser
from parsers.sbi_bank import SBIBankParser

# Order matters: more specific detectors first to avoid false positives
_PARSERS: list[BaseBankParser] = [
    HDFCCardParser(),      # unique: ~|~ + Card No: (CSV)
    HDFCCardPDFParser(),   # unique: PDF + HDFC card markers
    HDFCBankTXTParser(),   # unique: narration + closing balance (CSV)
    HDFCBankPDFParser(),   # unique: PDF + WithdrawalAmt. + DepositAmt.
    ICICICardParser(),     # unique: billingamountsign (CSV)
    ICICIBankParser(),     # unique: particulars + deposits + withdrawals (CSV)
    ICICIBankPDFParser(),  # unique: PDF + ICICI + Saving Account
    AmexCardParser(),      # unique: exactly 3 cols Date/Description/Amount
    ScapiaCardParser(),    # unique: PDF + ScapiaCoins
    AxisBankParser(),      # unique: tran. date (Axis Bank only)
    SBICardParser(),       # transaction date (no value date)
    AxisCardParser(),      # transaction date (no deposit+withdrawal pair)
    SBIBankParser(),       # most generic: value date / date
]

_BY_CODE: dict[str, BaseBankParser] = {p.bank_code: p for p in _PARSERS}


def detect_parser(
    content: bytes, bank_code: str | None = None, password: str | None = None
) -> BaseBankParser | None:
    """Return the appropriate parser. If bank_code given, use it directly.

    Raises PDFPasswordIncorrect if at least one PDF parser recognized the
    file as PDF-shaped but couldn't open it with the given password (or
    none was given). This takes priority over returning None, since "needs
    a password" and "not a supported format" are different outcomes the
    caller must distinguish.
    """
    if bank_code and bank_code in _BY_CODE:
        return _BY_CODE[bank_code]
    needs_password = False
    for parser in _PARSERS:
        try:
            if parser.detect(content, password=password):
                return parser
        except PDFPasswordIncorrect:
            needs_password = True
            continue
        except Exception:
            continue
    if needs_password:
        raise PDFPasswordIncorrect()
    return None
```

- [ ] **Step 9: Run tests to verify they pass**

Run: `cd python_service && python -m pytest tests/test_password_protected.py -v`
Expected: 6 passed

- [ ] **Step 10: Run the full existing parser test suite to check for regressions**

Run: `cd python_service && python -m pytest tests/ -v`
Expected: all tests pass (existing tests call `.detect(content)`/`.parse(content)`
positionally with one arg — the new `password` parameter has a default, so
these calls remain valid unchanged).

- [ ] **Step 11: Commit**

```bash
git add python_service/parsers/ python_service/tests/test_password_protected.py \
  python_service/tests/fixtures/hdfc_bank_pdf_locked.pdf python_service/requirements.txt
git commit -m "feat(parsers): thread password through PDF parser detect/parse"
```

---

## Task 2: Python — `/parse` endpoint returns `password_required`

**Repo:** `FinanceOS-Backend`

**Files:**
- Create: `python_service/parse_service.py`
- Modify: `python_service/main.py`
- Test: `python_service/tests/test_parse_service.py`

**Interfaces:**
- Consumes: `detect_parser(content, bank_code, password)` from Task 1 (raises `PDFPasswordIncorrect`).
- Produces: `build_parse_response(content: bytes, bank_code: str | None = None, password: str | None = None) -> dict | None` — returns `None` if no parser matched at all (caller raises the existing 422); otherwise a dict with keys `bank_code: str`, `count: int`, `last4: str | None`, `password_required: bool`, `transactions: list[dict]`. When `password_required` is `True`, `bank_code` is `""` (not `None` — the GraphQL field `bankCode` is non-null; callers must check `password_required` before reading `bank_code`), `count` is `0`, `transactions` is `[]`.

- [ ] **Step 1: Write the failing test**

Create `python_service/tests/test_parse_service.py`:

```python
import pathlib
from parse_service import build_parse_response

FIXTURES = pathlib.Path(__file__).parent / "fixtures"
LOCKED_PDF = (FIXTURES / "hdfc_bank_pdf_locked.pdf").read_bytes()


def test_password_required_when_none_given():
    result = build_parse_response(LOCKED_PDF)
    assert result["password_required"] is True
    assert result["bank_code"] == ""
    assert result["transactions"] == []


def test_password_required_when_wrong():
    result = build_parse_response(LOCKED_PDF, password="wrongpassword")
    assert result["password_required"] is True


def test_succeeds_with_correct_password():
    result = build_parse_response(LOCKED_PDF, password="secret123")
    assert result["password_required"] is False
    assert result["bank_code"] == "hdfc_bank_pdf"


def test_unrecognized_format_returns_none():
    assert build_parse_response(b"random,data,here\n1,2,3") is None


def test_recognized_unencrypted_file_unchanged():
    content = (FIXTURES / "hdfc_card.csv").read_bytes()
    result = build_parse_response(content)
    assert result["password_required"] is False
    assert result["bank_code"] == "hdfc_card"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd python_service && python -m pytest tests/test_parse_service.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'parse_service'`

- [ ] **Step 3: Create `parse_service.py`**

Create `python_service/parse_service.py`:

```python
from pdfminer.pdfdocument import PDFPasswordIncorrect
from parsers.detector import detect_parser


def build_parse_response(
    content: bytes, bank_code: str | None = None, password: str | None = None
) -> dict | None:
    """Detect and parse a statement. Returns None if no parser recognizes the
    format at all (caller should raise a 422). Returns a password-required
    response dict (never None) if the file is an encrypted PDF and the given
    password (or lack of one) didn't open it.
    """
    try:
        parser = detect_parser(content, bank_code, password)
    except PDFPasswordIncorrect:
        return _password_required_response()

    if parser is None:
        return None

    try:
        transactions = parser.parse(content, password=password)
    except PDFPasswordIncorrect:
        return _password_required_response()

    return {
        "bank_code": parser.bank_code,
        "count": len(transactions),
        "last4": parser.extract_last4(content),
        "password_required": False,
        "transactions": [
            {
                "postedAt": t.posted_at.isoformat(),
                "description": t.description,
                "amountMinorUnits": t.amount_minor_units,
                "currencyCode": t.currency_code,
                "sourceFingerprint": t.source_fingerprint,
                "rewardPoints": t.reward_points,
                "closingBalanceMinorUnits": t.closing_balance_minor_units,
                "statementRowIndex": t.statement_row_index,
            }
            for t in transactions
        ],
    }


def _password_required_response() -> dict:
    return {
        "bank_code": "",
        "count": 0,
        "last4": None,
        "password_required": True,
        "transactions": [],
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd python_service && python -m pytest tests/test_parse_service.py -v`
Expected: 5 passed

- [ ] **Step 5: Rewire `main.py`'s `/parse` endpoint to use it**

Modify `python_service/main.py` — replace the `/parse` handler body (the
existing lines building `parser = detect_parser(...)` through the return
dict) with:

```python
@app.post("/parse")
async def parse_file(
    file: UploadFile = File(...),
    bank_code: str | None = Form(default=None),
    password: str | None = Form(default=None),
):
    content = await file.read()
    result = build_parse_response(content, bank_code, password)
    if result is None:
        raise HTTPException(status_code=422, detail="Unrecognised statement format. Provide bank_code.")
    return result
```

Add the import at the top of `main.py`:
```python
from parse_service import build_parse_response
```
Remove the now-unused `from parsers.detector import detect_parser` import
from `main.py` if `detect_parser` isn't referenced anywhere else in the file
(check with `grep -n detect_parser main.py` — it should only appear in the
import line after this change).

- [ ] **Step 6: Run the full test suite**

Run: `cd python_service && python -m pytest tests/ -v`
Expected: all tests pass, including the existing (untouched) `/import`-path
tests and Task 1's parser tests.

- [ ] **Step 7: Commit**

```bash
git add python_service/parse_service.py python_service/main.py python_service/tests/test_parse_service.py
git commit -m "feat(api): /parse returns password_required instead of crashing on encrypted PDFs"
```

---

## Task 3: Node — sealed-box decryption + one-time keypair setup

**Repo:** `FinanceOS-Backend`

**Files:**
- Create: `node_api/src/services/passwordCrypto.ts`
- Create: `node_api/src/services/passwordCrypto.test.ts`
- Create: `node_api/scripts/generate-import-password-keypair.js`
- Modify: `node_api/package.json` (add `test` script)

**Interfaces:**
- Produces: `EncryptedPassword { ephemeralPublicKey: string; ciphertext: string }`, `decryptPassword(encrypted: EncryptedPassword): string` (throws if `IMPORT_PASSWORD_PRIVATE_KEY` is unset or decryption fails).

- [ ] **Step 1: Add a `test` script (this repo has no test infra yet)**

Modify `node_api/package.json`'s `"scripts"` block, adding:
```json
    "test": "node --require ts-node/register --test src/**/*.test.ts"
```
(`ts-node` is already resolvable via the existing `ts-node-dev` dependency —
no new package needed. Node's built-in `node:test` runner requires no
framework install either.)

- [ ] **Step 2: Write the one-time keypair generation script**

Create `node_api/scripts/generate-import-password-keypair.js`:

```javascript
const crypto = require('crypto');

const ecdh = crypto.createECDH('prime256v1');
ecdh.generateKeys();

console.log('IMPORT_PASSWORD_PRIVATE_KEY (put this in node_api/.env, never commit it):');
console.log(ecdh.getPrivateKey().toString('base64'));
console.log();
console.log('Public key (paste this into ImportPasswordCrypto.swift\'s backendPublicKey constant, Task 5):');
console.log(ecdh.getPublicKey().toString('base64'));
```

Run: `cd node_api && node scripts/generate-import-password-keypair.js`
Expected: two base64 strings printed (a 44-character one for the private
key, a 88-character one for the public key — 32 and 65 raw bytes
respectively). **Save both outputs** — the private key goes in
`node_api/.env` as `IMPORT_PASSWORD_PRIVATE_KEY=<value>` now; the public key
is needed again in Task 5.

Add `IMPORT_PASSWORD_PRIVATE_KEY=<the value you generated>` to
`node_api/.env` (and to `.env.example` as
`IMPORT_PASSWORD_PRIVATE_KEY=` with no value, if `.env.example` exists in
this repo — check with `ls node_api/.env.example`).

- [ ] **Step 3: Write the failing test using the committed fixture**

This fixture (a *different*, throwaway keypair — never the real one you
just generated in Step 2) is committed and used only to verify the
decrypt logic is byte-correct; it is not the deployment key.

Create `node_api/src/services/passwordCrypto.test.ts`:

```typescript
import { test } from 'node:test';
import assert from 'node:assert';
import { decryptPassword } from './passwordCrypto';

test('decrypts a known-good sealed password fixture', () => {
  process.env.IMPORT_PASSWORD_PRIVATE_KEY = 'jPD9lscFMxuYXKPA8rreVUQ1yCvF7I9cLXKJpvgHCqs=';
  const plaintext = decryptPassword({
    ephemeralPublicKey:
      'BMlpafZf5mr/ADpUNi81yut5ORTw8FZdJsm38X0+AXvNjAzkhzT4frPsmDHn1/fh88NuKrtqo+z3sYaJk5qy7g4=',
    ciphertext: 'AAAAAAAAAAAAAAAAbUGpYRAL7SenoVLK7IwGK3ZF5LOvH21l',
  });
  assert.strictEqual(plaintext, 'Test1234');
});

test('throws when IMPORT_PASSWORD_PRIVATE_KEY is not set', () => {
  delete process.env.IMPORT_PASSWORD_PRIVATE_KEY;
  assert.throws(() =>
    decryptPassword({ ephemeralPublicKey: 'AA==', ciphertext: 'AA==' }),
  );
});
```

- [ ] **Step 4: Run test to verify it fails**

Run: `cd node_api && npm test`
Expected: FAIL — `Cannot find module './passwordCrypto'`

- [ ] **Step 5: Implement `passwordCrypto.ts`**

Create `node_api/src/services/passwordCrypto.ts`:

```typescript
import crypto from 'crypto';

const HKDF_INFO = Buffer.from('financeos-import-password-v1', 'utf8');

export interface EncryptedPassword {
  ephemeralPublicKey: string;
  ciphertext: string;
}

export function decryptPassword(encrypted: EncryptedPassword): string {
  const privateKeyB64 = process.env.IMPORT_PASSWORD_PRIVATE_KEY;
  if (!privateKeyB64) {
    throw new Error('IMPORT_PASSWORD_PRIVATE_KEY is not set');
  }
  const privateKey = Buffer.from(privateKeyB64, 'base64');
  const ephemeralPublicKey = Buffer.from(encrypted.ephemeralPublicKey, 'base64');
  const combined = Buffer.from(encrypted.ciphertext, 'base64');

  const ecdh = crypto.createECDH('prime256v1');
  ecdh.setPrivateKey(privateKey);
  const sharedSecret = ecdh.computeSecret(ephemeralPublicKey);

  const aesKey = Buffer.from(
    crypto.hkdfSync('sha256', sharedSecret, Buffer.alloc(0), HKDF_INFO, 32),
  );

  const nonce = combined.subarray(0, 12);
  const tag = combined.subarray(combined.length - 16);
  const ciphertext = combined.subarray(12, combined.length - 16);

  const decipher = crypto.createDecipheriv('aes-256-gcm', aesKey, nonce);
  decipher.setAuthTag(tag);
  const plaintext = Buffer.concat([decipher.update(ciphertext), decipher.final()]);
  return plaintext.toString('utf8');
}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `cd node_api && npm test`
Expected: 2 tests pass

- [ ] **Step 7: Commit**

```bash
git add node_api/src/services/passwordCrypto.ts node_api/src/services/passwordCrypto.test.ts \
  node_api/scripts/generate-import-password-keypair.js node_api/package.json
git commit -m "feat(crypto): add ECDH+HKDF+AES-GCM password decryption"
```
Do not commit `.env` (already gitignored — verify with `git status` that
it doesn't appear).

---

## Task 4: Node — GraphQL schema + resolver wiring

**Repo:** `FinanceOS-Backend`

**Files:**
- Modify: `node_api/src/schema/typedefs.graphql`
- Modify: `node_api/src/services/python.ts`
- Modify: `node_api/src/resolvers/preview.ts`
- Modify: `node_api/src/resolvers/upload.ts`
- Test: `node_api/src/resolvers/preview.test.ts`, `node_api/src/resolvers/upload.test.ts`

**Interfaces:**
- Consumes: `decryptPassword(encrypted): string` from Task 3.
- Produces: `previewStatement(file: Upload!, password: EncryptedPassword): StatementPreview!` where `StatementPreview.passwordRequired: Boolean!`; `uploadStatement(ledgerId: ID!, file: Upload!, password: EncryptedPassword): ImportResult!` (throws if the password was wrong).

- [ ] **Step 1: Update the schema**

Modify `node_api/src/schema/typedefs.graphql` — add the new input type,
add `passwordRequired` to `StatementPreview`, add `password` args to both
mutations:

```graphql
input EncryptedPassword {
  ephemeralPublicKey: String!
  ciphertext: String!
}

type StatementPreview {
  bankCode: String!
  last4: String
  transactionCount: Int!
  passwordRequired: Boolean!
}
```
(replace the existing `type StatementPreview { ... }` block with this one).

```graphql
type Mutation {
  uploadStatement(ledgerId: ID!, file: Upload!, password: EncryptedPassword): ImportResult!
  previewStatement(file: Upload!, password: EncryptedPassword): StatementPreview!
  createLedger(input: CreateLedgerInput!): Ledger!
  updateLedger(id: ID!, input: UpdateLedgerInput!): Ledger!
  deleteLedger(id: ID!): Boolean!
  recategorize(transactionId: ID!, category: String!): Transaction!
  deleteTransaction(id: ID!): Boolean!
  createBank(input: CreateBankInput!): Bank!
  clearAllData: Boolean!
}
```
(only `uploadStatement` and `previewStatement` change; the rest of the
`Mutation` type is unchanged — replace the whole block for clarity, keeping
the other 7 fields as they already are).

- [ ] **Step 2: Update `python.ts`**

Modify `node_api/src/services/python.ts` — update `ParseResponse` and
`parseFile`:

```typescript
export interface ParseResponse {
  bank_code: string;
  count: number;
  last4: string | null;
  password_required: boolean;
  transactions: ParsedTransaction[];
}

export async function parseFile(
  fileBuffer: Buffer,
  filename: string,
  bankCode?: string,
  password?: string,
): Promise<ParseResponse> {
  const form = new FormData();
  form.append('file', fileBuffer, { filename });
  if (bankCode) form.append('bank_code', bankCode);
  if (password) form.append('password', password);

  const res = await axios.post<ParseResponse>(`${PYTHON_URL}/parse`, form, {
    headers: form.getHeaders(),
  });
  return res.data;
}
```
(the rest of `python.ts` — `ParsedTransaction`, `ImportResponse`,
`importTransactions`, `getAnalytics` — is unchanged).

- [ ] **Step 3: Write the failing resolver tests**

Create `node_api/src/resolvers/preview.test.ts`:

```typescript
import { test, mock } from 'node:test';
import assert from 'node:assert';

test('previewStatement maps password_required through', async (t) => {
  const pythonService = { parseFile: mock.fn(async () => ({
    bank_code: '',
    count: 0,
    last4: null,
    password_required: true,
    transactions: [],
  })) };
  const passwordCrypto = { decryptPassword: mock.fn(() => 'plaintext-password') };

  t.mock.module('../services/python', { namedExports: pythonService });
  t.mock.module('../services/passwordCrypto', { namedExports: passwordCrypto });
  const { previewResolvers } = await import('./preview');

  const fakeFile = Promise.resolve({
    filename: 'test.pdf',
    mimetype: 'application/pdf',
    encoding: '7bit',
    createReadStream: () => {
      const { Readable } = require('stream');
      return Readable.from([Buffer.from('fake pdf bytes')]);
    },
  });

  const result = await previewResolvers.Mutation.previewStatement(null, {
    file: fakeFile,
    password: { ephemeralPublicKey: 'AA==', ciphertext: 'AA==' },
  });

  assert.strictEqual(result.passwordRequired, true);
  assert.strictEqual(passwordCrypto.decryptPassword.mock.calls.length, 1);
});
```

Create `node_api/src/resolvers/upload.test.ts`:

```typescript
import { test } from 'node:test';
import assert from 'node:assert';

test('uploadStatement throws when password_required comes back true', async (t) => {
  const pythonService = {
    parseFile: async () => ({
      bank_code: '',
      count: 0,
      last4: null,
      password_required: true,
      transactions: [],
    }),
    importTransactions: async () => {
      throw new Error('should not be called');
    },
  };
  const passwordCrypto = { decryptPassword: () => 'plaintext-password' };

  t.mock.module('../services/python', { namedExports: pythonService });
  t.mock.module('../services/passwordCrypto', { namedExports: passwordCrypto });
  const { uploadResolvers } = await import('./upload');

  const fakeFile = Promise.resolve({
    filename: 'test.pdf',
    mimetype: 'application/pdf',
    encoding: '7bit',
    createReadStream: () => {
      const { Readable } = require('stream');
      return Readable.from([Buffer.from('fake pdf bytes')]);
    },
  });

  await assert.rejects(
    uploadResolvers.Mutation.uploadStatement(null, {
      ledgerId: 'fake-id',
      file: fakeFile,
      password: { ephemeralPublicKey: 'AA==', ciphertext: 'AA==' },
    }),
  );
});
```

- [ ] **Step 4: Run tests to verify they fail**

Run: `cd node_api && npm test`
Expected: FAIL — `previewResolvers.Mutation.previewStatement` doesn't yet
accept/thread a `password` argument (result.passwordRequired is `undefined`).

- [ ] **Step 5: Update `preview.ts`**

Modify `node_api/src/resolvers/preview.ts`:

```typescript
import { parseFile } from '../services/python';
import { decryptPassword, EncryptedPassword } from '../services/passwordCrypto';

interface FileUpload {
  filename: string;
  mimetype: string;
  encoding: string;
  createReadStream: () => NodeJS.ReadableStream;
}

export const previewResolvers = {
  Mutation: {
    previewStatement: async (
      _: unknown,
      { file, password }: { file: Promise<FileUpload>; password?: EncryptedPassword },
    ) => {
      const { filename, createReadStream } = await file;

      const chunks: Buffer[] = [];
      await new Promise<void>((resolve, reject) => {
        const stream = createReadStream();
        stream.on('data', (chunk: Buffer) => chunks.push(chunk));
        stream.on('end', resolve);
        stream.on('error', reject);
      });
      const buffer = Buffer.concat(chunks);

      const plaintextPassword = password ? decryptPassword(password) : undefined;
      const parsed = await parseFile(buffer, filename, undefined, plaintextPassword);

      return {
        bankCode: parsed.bank_code,
        last4: parsed.last4,
        transactionCount: parsed.count,
        passwordRequired: parsed.password_required,
      };
    },
  },
};
```

- [ ] **Step 6: Update `upload.ts`**

Modify `node_api/src/resolvers/upload.ts`:

```typescript
import { parseFile, importTransactions } from '../services/python';
import { decryptPassword, EncryptedPassword } from '../services/passwordCrypto';
import prisma from '../prisma/client';

interface FileUpload {
  filename: string;
  mimetype: string;
  encoding: string;
  createReadStream: () => NodeJS.ReadableStream;
}

export const uploadResolvers = {
  Mutation: {
    uploadStatement: async (
      _: unknown,
      {
        ledgerId,
        file,
        password,
      }: { ledgerId: string; file: Promise<FileUpload>; password?: EncryptedPassword },
    ) => {
      const { filename, createReadStream } = await file;

      const chunks: Buffer[] = [];
      await new Promise<void>((resolve, reject) => {
        const stream = createReadStream();
        stream.on('data', (chunk: Buffer) => chunks.push(chunk));
        stream.on('end', resolve);
        stream.on('error', reject);
      });
      const buffer = Buffer.concat(chunks);

      const plaintextPassword = password ? decryptPassword(password) : undefined;
      const parsed = await parseFile(buffer, filename, undefined, plaintextPassword);
      if (parsed.password_required) {
        throw new Error('Incorrect or missing password for this file');
      }
      const imported = await importTransactions(ledgerId, parsed.transactions);

      const ledger = await prisma.ledger.findUniqueOrThrow({
        where: { id: ledgerId },
        include: { bank: true },
      });

      return {
        imported: imported.imported,
        duplicates: imported.duplicates,
        errors: imported.errors,
        ledger,
      };
    },
  },
};
```

- [ ] **Step 7: Run tests to verify they pass**

Run: `cd node_api && npm test`
Expected: all tests pass (Task 3's 2 + Task 4's 2)

- [ ] **Step 8: Type-check and start the service locally**

Run: `cd node_api && npx tsc --noEmit`
Expected: no errors

Run (with `financeos-backend`'s docker-compose stack up, per this repo's
existing dev-setup docs): confirm `node_api` starts without schema errors —
GraphQL SDL parse failures surface immediately at startup.

- [ ] **Step 9: Commit**

```bash
git add node_api/src/schema/typedefs.graphql node_api/src/services/python.ts \
  node_api/src/resolvers/preview.ts node_api/src/resolvers/upload.ts \
  node_api/src/resolvers/preview.test.ts node_api/src/resolvers/upload.test.ts
git commit -m "feat(graphql): thread encrypted password through preview/uploadStatement"
```

**This completes the `FinanceOS-Backend` half. Ship/merge this before
starting Task 5 — Task 8's codegen step needs a live backend reflecting
this schema.**

---

## Task 5: Swift — `ImportPasswordCrypto` (seal + cross-language fixture)

**Repo:** `FinanceOS` (this repo)

**Files:**
- Create: `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/Services/ImportPasswordCrypto.swift`
- Test: `Apps/FinanceOSMac/FinanceOSMacSnapshotTests/Flows/ImportPasswordCryptoTests.swift`

**Interfaces:**
- Produces: `ImportPasswordCrypto.SealedPassword { ephemeralPublicKey: String; ciphertext: String }`, `ImportPasswordCrypto.seal(_ password: String, recipientPublicKey: P256.KeyAgreement.PublicKey = backendPublicKey) throws -> SealedPassword`, `ImportPasswordCrypto.backendPublicKey: P256.KeyAgreement.PublicKey`.

- [ ] **Step 1: Write the cross-language interop test first**

This proves `CryptoKit`'s ECDH + HKDF match Node's `crypto` byte-for-byte,
using the exact same fixture values Task 3's Node test used (same ephemeral
private key, same backend public key, same expected shared secret and AES
key — all precomputed and verified against Node already).

Create `Apps/FinanceOSMac/FinanceOSMacSnapshotTests/Flows/ImportPasswordCryptoTests.swift`:

```swift
import Crypto
import XCTest

final class ImportPasswordCryptoTests: XCTestCase {
    // Fixed test-only fixture values — the same ones verified against Node's
    // `crypto` module in FinanceOS-Backend's passwordCrypto.test.ts. This is
    // NOT the real deployment keypair (never committed anywhere).
    private let ephemeralPrivateRawBase64 = "ZDnlXSkWgS3aWEtJ/5w1U4C4M8gzJ46LMWMN2sVyPfE="
    private let backendPublicRawBase64 =
        "BJb0lVFCWMLnP8Aoxk1VVu3ECfSkoUL8oknzkukL8Ten0NOCd5DIjbxNEWt+lJfpkgSAJm1W21N93n8BSJiYHR4="
    private let expectedSharedSecretBase64 = "ZGTr5gsbVCrhJcPDLrX5n1wwbkbGK6Y/NQsREauI7oU="
    private let expectedAESKeyBase64 = "pslNMm2AcUhIunmNH7WrPSOdAe0bc8Cjol0Q92HpzY8="

    func test_ecdh_and_hkdf_match_node_fixture() throws {
        let ephemeralPrivateKey = try P256.KeyAgreement.PrivateKey(
            rawRepresentation: Data(base64Encoded: ephemeralPrivateRawBase64)!
        )
        let backendPublicKey = try P256.KeyAgreement.PublicKey(
            x963Representation: Data(base64Encoded: backendPublicRawBase64)!
        )

        let sharedSecret = try ephemeralPrivateKey.sharedSecretFromKeyAgreement(with: backendPublicKey)
        let sharedSecretData = sharedSecret.withUnsafeBytes { Data($0) }
        XCTAssertEqual(
            sharedSecretData.base64EncodedString(), expectedSharedSecretBase64,
            "ECDH shared secret mismatch — check x963 vs raw public-key encoding first"
        )

        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data("financeos-import-password-v1".utf8),
            outputByteCount: 32
        )
        let keyData = symmetricKey.withUnsafeBytes { Data($0) }
        XCTAssertEqual(
            keyData.base64EncodedString(), expectedAESKeyBase64,
            "HKDF output mismatch — check salt/info string match Node's exactly"
        )
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -workspace FinanceOS.xcworkspace -scheme FinanceOSMac \
  -destination 'platform=macOS,arch=arm64' \
  -only-testing:FinanceOSMacSnapshotTests/ImportPasswordCryptoTests`
Expected: FAIL — `Crypto` module / `P256` not found (nothing imports
`CryptoKit` yet in this target) or compile error, since `ImportPasswordCrypto.swift`
doesn't exist yet and this test file references only test-local `CryptoKit`
types directly (no dependency on the production file) — it should compile
once `import Crypto` resolves. If it fails purely on `import Crypto`, use
`import CryptoKit` instead (the module is called `CryptoKit` when imported
from an app target; `Crypto` is the underlying Swift Crypto package name
used internally — check by trying `import CryptoKit` first, since that's
the standard Apple-platform import).

- [ ] **Step 3: Fix the import and re-run**

Change `import Crypto` to `import CryptoKit` at the top of the test file if
Step 2 showed that was the issue.

Run the same command again.
Expected: PASS (this test has no dependency on `ImportPasswordCrypto.swift`
at all — it only exercises raw `CryptoKit` primitives against the fixture,
so it can pass before Step 4 exists. This is intentional: it isolates
"does CryptoKit interop with Node" from "is `seal()`'s wire format correct.")

- [ ] **Step 4: Write `ImportPasswordCrypto.swift`**

Create `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/Services/ImportPasswordCrypto.swift`:

```swift
import CryptoKit
import Foundation

/// Seals a plaintext password for transmission to `financeos-backend` using
/// ephemeral-ECDH + HKDF-SHA256 + AES-256-GCM against the backend's permanent
/// public key. The plaintext password never leaves the device — only the
/// sealed envelope does. See docs/superpowers/specs/2026-07-06-password-protected-pdf-import-design.md.
enum ImportPasswordCrypto {
    struct SealedPassword {
        let ephemeralPublicKey: String
        let ciphertext: String
    }

    enum CryptoError: Error {
        case sealingFailed
    }

    /// Public key for the backend's permanent P-256 keypair (private half lives only
    /// in node_api's IMPORT_PASSWORD_PRIVATE_KEY env var). Generated once via
    /// FinanceOS-Backend/node_api/scripts/generate-import-password-keypair.js — replace
    /// this value with your own deployment's output; it is safe to commit since it's public.
    static let backendPublicKey: P256.KeyAgreement.PublicKey = {
        let base64 = "REPLACE_WITH_YOUR_GENERATED_PUBLIC_KEY_FROM_TASK_3_STEP_2"
        guard let data = Data(base64Encoded: base64),
              let key = try? P256.KeyAgreement.PublicKey(x963Representation: data) else {
            fatalError("ImportPasswordCrypto.backendPublicKey is not a valid P-256 public key")
        }
        return key
    }()

    static func seal(
        _ password: String,
        recipientPublicKey: P256.KeyAgreement.PublicKey = backendPublicKey
    ) throws -> SealedPassword {
        let ephemeralPrivateKey = P256.KeyAgreement.PrivateKey()
        let sharedSecret = try ephemeralPrivateKey.sharedSecretFromKeyAgreement(with: recipientPublicKey)
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data("financeos-import-password-v1".utf8),
            outputByteCount: 32
        )
        let sealedBox = try AES.GCM.seal(Data(password.utf8), using: symmetricKey)
        guard let combined = sealedBox.combined else {
            throw CryptoError.sealingFailed
        }
        return SealedPassword(
            ephemeralPublicKey: ephemeralPrivateKey.publicKey.x963Representation.base64EncodedString(),
            ciphertext: combined.base64EncodedString()
        )
    }
}
```

**Do not leave the `REPLACE_WITH_YOUR_GENERATED_PUBLIC_KEY_FROM_TASK_3_STEP_2`
placeholder in place** — substitute the actual public key you generated and
saved in Task 3, Step 2 (`node scripts/generate-import-password-keypair.js`'s
second printed value). This is the one value in this entire plan that is
inherently deployment-specific and cannot be a fixed literal — every other
value in this plan is real and already verified.

- [ ] **Step 5: Write the self-consistency test for the real `seal()` API**

Add to `ImportPasswordCryptoTests.swift`:

```swift
    func test_seal_produces_a_ciphertext_the_recipient_can_decrypt() throws {
        // Simulate "the backend": a locally-generated test keypair, never the real one.
        let testRecipientPrivateKey = P256.KeyAgreement.PrivateKey()
        let sealed = try ImportPasswordCrypto.seal(
            "correct horse battery staple",
            recipientPublicKey: testRecipientPrivateKey.publicKey
        )

        let ephemeralPublicKey = try P256.KeyAgreement.PublicKey(
            x963Representation: Data(base64Encoded: sealed.ephemeralPublicKey)!
        )
        let sharedSecret = try testRecipientPrivateKey.sharedSecretFromKeyAgreement(with: ephemeralPublicKey)
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data("financeos-import-password-v1".utf8),
            outputByteCount: 32
        )
        let combined = Data(base64Encoded: sealed.ciphertext)!
        let sealedBox = try AES.GCM.SealedBox(combined: combined)
        let decrypted = try AES.GCM.open(sealedBox, using: symmetricKey)

        XCTAssertEqual(String(data: decrypted, encoding: .utf8), "correct horse battery staple")
    }
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `xcodebuild test -workspace FinanceOS.xcworkspace -scheme FinanceOSMac \
  -destination 'platform=macOS,arch=arm64' \
  -only-testing:FinanceOSMacSnapshotTests/ImportPasswordCryptoTests`
Expected: 2 tests pass

- [ ] **Step 7: Lint and commit**

Run: `swiftlint lint --strict --quiet`
Expected: no output

```bash
git add Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/Services/ImportPasswordCrypto.swift \
  Apps/FinanceOSMac/FinanceOSMacSnapshotTests/Flows/ImportPasswordCryptoTests.swift
git commit -m "feat(import): add ImportPasswordCrypto (sealed-box password encryption)"
```

---

## Task 6: Swift — `ImportPasswordStore` (Keychain)

**Repo:** `FinanceOS`

**Files:**
- Create: `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/Services/ImportPasswordStore.swift`
- Test: `Apps/FinanceOSMac/FinanceOSMacSnapshotTests/Flows/ImportPasswordStoreTests.swift`

**Interfaces:**
- Produces: `protocol ImportPasswordStoring { func password(for ledgerId: UUID) -> String?; func save(_ password: String, for ledgerId: UUID) }`, `struct ImportPasswordStore: ImportPasswordStoring` (real Keychain-backed implementation).

- [ ] **Step 1: Write the failing test**

Create `Apps/FinanceOSMac/FinanceOSMacSnapshotTests/Flows/ImportPasswordStoreTests.swift`:

```swift
@testable import FinanceOSMac
import XCTest

final class ImportPasswordStoreTests: XCTestCase {
    // Isolated service identifier — never touches the real app's Keychain entries.
    private let store = ImportPasswordStore(serviceIdentifier: "com.financeos.import.pdfpassword.test")
    private let ledgerId = UUID()

    override func tearDown() {
        // Best-effort cleanup so repeated test runs don't accumulate stale items.
        store.delete(for: ledgerId)
        super.tearDown()
    }

    func test_returns_nil_when_nothing_saved() {
        XCTAssertNil(store.password(for: ledgerId))
    }

    func test_saves_and_retrieves_a_password() {
        store.save("hunter2", for: ledgerId)
        XCTAssertEqual(store.password(for: ledgerId), "hunter2")
    }

    func test_save_overwrites_an_existing_entry() {
        store.save("first", for: ledgerId)
        store.save("second", for: ledgerId)
        XCTAssertEqual(store.password(for: ledgerId), "second")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -workspace FinanceOS.xcworkspace -scheme FinanceOSMac \
  -destination 'platform=macOS,arch=arm64' \
  -only-testing:FinanceOSMacSnapshotTests/ImportPasswordStoreTests`
Expected: FAIL — `ImportPasswordStore` doesn't exist

- [ ] **Step 3: Implement `ImportPasswordStore.swift`**

Create `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/Services/ImportPasswordStore.swift`:

```swift
import Foundation
import Security

/// Persists PDF-statement passwords in the macOS Keychain, keyed by ledger id, so a
/// user isn't re-prompted every time they import from an account they've already
/// unlocked once. Injected as a protocol so `ImportViewModel` tests can fake it.
protocol ImportPasswordStoring {
    func password(for ledgerId: UUID) -> String?
    func save(_ password: String, for ledgerId: UUID)
}

struct ImportPasswordStore: ImportPasswordStoring {
    private let serviceIdentifier: String

    init(serviceIdentifier: String = "com.financeos.import.pdfpassword") {
        self.serviceIdentifier = serviceIdentifier
    }

    func password(for ledgerId: UUID) -> String? {
        var query = baseQuery(for: ledgerId)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func save(_ password: String, for ledgerId: UUID) {
        let data = Data(password.utf8)
        let query = baseQuery(for: ledgerId)

        var attributesToUpdate: [String: Any] = [:]
        attributesToUpdate[kSecValueData as String] = data
        let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)

        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    func delete(for ledgerId: UUID) {
        SecItemDelete(baseQuery(for: ledgerId) as CFDictionary)
    }

    private func baseQuery(for ledgerId: UUID) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: ledgerId.uuidString,
        ]
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -workspace FinanceOS.xcworkspace -scheme FinanceOSMac \
  -destination 'platform=macOS,arch=arm64' \
  -only-testing:FinanceOSMacSnapshotTests/ImportPasswordStoreTests`
Expected: 3 tests pass

- [ ] **Step 5: Lint and commit**

Run: `swiftlint lint --strict --quiet`
Expected: no output

```bash
git add Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/Services/ImportPasswordStore.swift \
  Apps/FinanceOSMac/FinanceOSMacSnapshotTests/Flows/ImportPasswordStoreTests.swift
git commit -m "feat(import): add ImportPasswordStore (Keychain-backed password persistence)"
```

---

## Task 7: Swift — wire the retry flow into `ImportViewModel`

**Repo:** `FinanceOS`

**Files:**
- Modify: `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportSession.swift`
- Modify: `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportViewModel.swift`
- Modify: `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportViewModelStateManagement.swift`
- Modify: `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/Services/ImportFileParser.swift`
- Modify: `Apps/FinanceOSMac/GraphQL/Operations/Mutations.graphql`
- Modify: `Packages/FinanceCore/Sources/FinanceCore/Importing/TransactionImportError.swift` (doc comment only — the `ParseOptions` reference is stale)
- Test: `Apps/FinanceOSMac/FinanceOSMacSnapshotTests/Flows/ImportViewModelPasswordTests.swift`

**Interfaces:**
- Consumes: `ImportPasswordCrypto.seal(_:)` (Task 5), `ImportPasswordStoring` (Task 6).
- Produces: `ImportSession.filePasswords: [URL: String]`; `StatementParsingProtocol.parse(fileURL: URL, password: String?) async throws -> ParsedStatement` (signature change — was `parse(fileURL:)`); `ImportViewModel.init(graphQLClient:initialTarget:fileParser:passwordStore:)` (new `passwordStore` param, defaults to real `ImportPasswordStore()`); `ImportViewModel.pendingPasswordRequest: PasswordPromptRequest?` (drives the sheet from Task 8) where `PasswordPromptRequest` is `Identifiable` with `let fileURL: URL`, `let filename: String`, `let isRetry: Bool`.

- [ ] **Step 1: Update the GraphQL mutation operations**

Modify `Apps/FinanceOSMac/GraphQL/Operations/Mutations.graphql`:

```graphql
mutation UploadStatement($ledgerId: ID!, $file: Upload!, $password: EncryptedPassword) {
  uploadStatement(ledgerId: $ledgerId, file: $file, password: $password) {
    imported
    duplicates
    errors
    ledger {
      id
      displayName
      balance {
        value
        currencyCode
      }
    }
  }
}

mutation PreviewStatement($file: Upload!, $password: EncryptedPassword) {
  previewStatement(file: $file, password: $password) {
    bankCode
    last4
    transactionCount
    passwordRequired
  }
}
```
(leave every other mutation in this file unchanged).

Regenerate codegen — **this requires Tasks 1–4 to already be live on a
locally running backend** (`bash Scripts/codegen.sh local`, per this repo's
existing codegen workflow). Run it now:

Run: `bash Scripts/codegen.sh local`
Expected: exits 0, `Apps/FinanceOSMac/GraphQL/schema.graphql` updates to
include `EncryptedPassword` and `passwordRequired`, and generated
`PreviewStatementMutation`/`UploadStatementMutation` Swift types gain a
`password` initializer parameter.

If this fails because no local backend is running: start it per this
repo's existing dev-setup instructions (`financeos-backend`'s
`docker-compose up`), confirm Tasks 1–4 are checked out there, then retry.

- [ ] **Step 2: Update `TransactionImportError`'s stale doc comment**

Modify `Packages/FinanceCore/Sources/FinanceCore/Importing/TransactionImportError.swift`,
line 24 — `ParseOptions` no longer exists (retired with the old
`FinanceParsers` package):

```swift
    /// The file is encrypted and a password must be supplied.
    case passwordProtected(String)
```

- [ ] **Step 3: Update `ImportSession.swift`**

Read the current file first (`Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportSession.swift`)
to see its exact existing property list, then add one property to the
`@Observable` class (alongside the existing `fileURLs`, `parsedStatements`,
`selectedTarget`, etc.):

```swift
    var filePasswords: [URL: String] = [:]
```

Also update `ImportSession.reset()` (in the same file) to clear it:
```swift
    func reset() {
        fileURLs = []
        parsedStatements = []
        selectedTarget = nil
        errorMessage = nil
        importResult = nil
        isLoading = false
        filePasswords = [:]
    }
```
(keep every other line already in `reset()` — this only adds the
`filePasswords = [:]` line; check the exact current body first since this
plan doesn't have it verbatim).

- [ ] **Step 4: Update `StatementParsingProtocol` and `ImportFileParser`**

Modify `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/Services/ImportFileParser.swift`:

```swift
@preconcurrency import Apollo
import FinanceCore
import FinanceOSAPI
import Foundation
import OSLog

protocol StatementParsingProtocol: Sendable {
    func parse(fileURL: URL, password: String?) async throws -> ParsedStatement
}

/// Detects bank/last4/transaction-count for a statement by previewing it against
/// financeos-backend, which owns statement parsing end to end. Falls back to
/// filename-based last4 extraction for banks the backend can't yet extract from
/// statement content.
struct ImportFileParser: StatementParsingProtocol {
    private let logger = FinanceLogger.importPipeline
    private let graphQLClient: ApolloGraphQLClient

    init(graphQLClient: ApolloGraphQLClient) {
        self.graphQLClient = graphQLClient
    }

    func parse(fileURL: URL, password: String? = nil) async throws -> ParsedStatement {
        let fileName = fileURL.lastPathComponent
        let fileData = try Data(contentsOf: fileURL)
        let file = GraphQLFile(
            fieldName: "file",
            originalName: fileName,
            mimeType: "text/csv",
            data: fileData
        )
        let sealedPassword = try password.map { try ImportPasswordCrypto.seal($0) }
        let mutation = PreviewStatementMutation(
            file: "",
            password: sealedPassword.map {
                .some(EncryptedPassword(ephemeralPublicKey: $0.ephemeralPublicKey, ciphertext: $0.ciphertext))
            } ?? .null
        )
        let response = try await graphQLClient.upload(mutation: mutation, files: [file])
        let preview = response.previewStatement

        if preview.passwordRequired {
            throw FinanceCore.TransactionImportError.passwordProtected(fileName)
        }

        let filenameMetadata = FilenameMetadataExtractor().extractMetadata(from: fileName)
        let last4 = preview.last4 ?? filenameMetadata.accountLast4
        let isCard = preview.bankCode.contains("card")
        let bankName = Self.bankName(fromBankCode: preview.bankCode)

        logger.logInfo(
            "Previewed {file}: {count} txns from {bank}",
            ["file": fileName, "count": preview.transactionCount, "bank": bankName]
        )

        return ParsedStatement(
            bankName: bankName,
            accountName: bankName,
            accountLast4: isCard ? nil : last4,
            cardLast4: isCard ? last4 : nil,
            transactions: []
        )
    }

    private static func bankName(fromBankCode bankCode: String) -> String {
        let prefix = bankCode.split(separator: "_").first.map(String.init) ?? bankCode
        switch prefix.lowercased() {
        case "hdfc": return "HDFC"
        case "icici": return "ICICI"
        case "amex": return "American Express"
        case "axis": return "Axis"
        case "sbi": return "SBI"
        case "scapia": return "Scapia"
        default: return prefix.uppercased()
        }
    }
}
```

**Note:** `EncryptedPassword` here is the Apollo-generated Swift type for the
GraphQL `input EncryptedPassword` added in Task 4, Step 1 — it comes from
Step 1's codegen run, not something to hand-write. It is a different type
from `ImportPasswordCrypto.SealedPassword` (our own internal return type
from `seal()`) — the code above converts one to the other.

**Note:** the exact generated `PreviewStatementMutation` initializer shape
for an optional GraphQL input type depends on Apollo's codegen output from
Step 1 — Apollo 2.x typically generates `GraphQLNullable<EncryptedPassword>`
for a nullable input argument, exposed as `.some(value)` / `.null` /
`.none`. Check the actual generated file
(`Apps/FinanceOSMac/GraphQL/Generated/Operations/PreviewStatementMutation.graphql.swift`
or similar, wherever Step 1's codegen wrote it) for the exact parameter
type and adjust the `password:` argument construction above to match — the
shape sketched here (`GraphQLNullable`-style `.some`/`.null`) is Apollo's
documented convention as of the version already pinned in this repo
(confirmed via `Scripts/codegen.sh` / the Apollo version pinned in the
earlier `fix(graphql): ... pin apollo version` commit on `main`), but
verify against the real generated file rather than assuming.

- [ ] **Step 5: Wire the retry loop in `ImportViewModel`**

Read `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportViewModel.swift`
in full first (it was shown in this session's earlier work — `parseFiles()`'s
per-file loop is the one to change). Modify the loop inside `parseFiles()`
(currently a `for fileURL in importSession.fileURLs { let statement = try
await parser.parse(fileURL: fileURL); ... }`) to:

```swift
            for fileURL in importSession.fileURLs {
                do {
                    let statement = try await parseWithPasswordRetry(fileURL: fileURL, parser: parser)
                    statements.append(statement)
                    currentFileIndex += 1
                } catch let error as FinanceCore.TransactionImportError {
                    importSession.errorMessage = "Error parsing \(fileURL.lastPathComponent): \(error.userMessage)"
                    importSession.parsedStatements = []
                    importSession.isLoading = false
                    currentFileIndex = 0
                    totalFilesToParse = 0
                    phase = .idle
                    return
                } catch {
                    let fileName = fileURL.lastPathComponent
                    let errorDesc = error.localizedDescription
                    importSession.errorMessage = "Error parsing \(fileName): \(errorDesc)"
                    importSession.parsedStatements = []
                    importSession.isLoading = false
                    currentFileIndex = 0
                    totalFilesToParse = 0
                    phase = .idle
                    return
                }
            }
```
(keep the rest of `parseFiles()` — the code before and after this loop —
exactly as it already is).

Add the new private helper (in `ImportViewModelStateManagement.swift`,
alongside `autoSelectMatchingTarget()`/`loadTargetsOnAppear()`):

```swift
    /// Tries `previewStatement` for one file, resolving a password via Keychain or
    /// the password-prompt sheet if the backend reports `passwordRequired`. Loops
    /// until the file parses, the user cancels (throws `.passwordProtected` to
    /// abort this file), or a non-password error occurs.
    func parseWithPasswordRetry(fileURL: URL, parser: any StatementParsingProtocol) async throws -> ParsedStatement {
        var isRetry = false
        var password: String? = knownPassword(for: fileURL)

        while true {
            do {
                let statement = try await parser.parse(fileURL: fileURL, password: password)
                if let password {
                    importSession.filePasswords[fileURL] = password
                }
                return statement
            } catch FinanceCore.TransactionImportError.passwordProtected {
                guard let entered = await requestPassword(for: fileURL, isRetry: isRetry) else {
                    throw FinanceCore.TransactionImportError.passwordProtected(fileURL.lastPathComponent)
                }
                password = entered
                isRetry = true
            }
        }
    }

    private func knownPassword(for fileURL: URL) -> String? {
        guard case let .ledger(ledgerId) = importSession.selectedTarget else { return nil }
        return passwordStore.password(for: ledgerId)
    }

    /// Presents the password sheet and suspends until the user submits or cancels.
    /// Returns nil on cancel. Saving to Keychain (if the user checked that option)
    /// happens here, keyed by the currently-resolved target ledger if there is one.
    @MainActor
    private func requestPassword(for fileURL: URL, isRetry: Bool) async -> String? {
        await withCheckedContinuation { continuation in
            pendingPasswordRequest = PasswordPromptRequest(
                fileURL: fileURL,
                filename: fileURL.lastPathComponent,
                isRetry: isRetry,
                onSubmit: { [weak self] password, saveToKeychain in
                    guard let self else { return }
                    if saveToKeychain, case let .ledger(ledgerId) = self.importSession.selectedTarget {
                        self.passwordStore.save(password, for: ledgerId)
                    }
                    self.pendingPasswordRequest = nil
                    continuation.resume(returning: password)
                },
                onCancel: { [weak self] in
                    self?.pendingPasswordRequest = nil
                    continuation.resume(returning: nil)
                }
            )
        }
    }
```

Add `PasswordPromptRequest` (new small type, same file):

```swift
struct PasswordPromptRequest: Identifiable {
    let id = UUID()
    let fileURL: URL
    let filename: String
    let isRetry: Bool
    let onSubmit: (String, Bool) -> Void
    let onCancel: () -> Void
}
```

Add the two new properties to `ImportViewModel` (in `ImportViewModel.swift`,
alongside the existing `var ledgers`/`var banks`/etc.):

```swift
    var pendingPasswordRequest: PasswordPromptRequest?
    private let passwordStore: any ImportPasswordStoring
```

Update `ImportViewModel.init` to accept and default the new dependency:

```swift
    init(
        graphQLClient: ApolloGraphQLClient,
        initialTarget: TransactionImportTarget? = nil,
        fileParser: (any StatementParsingProtocol)? = nil,
        passwordStore: (any ImportPasswordStoring)? = nil
    ) {
        importSession = ImportSession()
        self.graphQLClient = graphQLClient
        self.fileParser = fileParser ?? ImportFileParser(graphQLClient: graphQLClient)
        self.passwordStore = passwordStore ?? ImportPasswordStore()
        if let initialTarget {
            importSession.selectedTarget = initialTarget
        }
    }
```

Update `uploadFiles()` (in `ImportViewModel.swift`) to pass the
already-resolved password through:

```swift
    private func uploadFiles(ledgerId: UUID) async throws -> (inserted: Int, skipped: Int) {
        var totalInserted = 0
        var totalSkipped = 0
        for fileURL in importSession.fileURLs {
            let fileData = try Data(contentsOf: fileURL)
            let file = GraphQLFile(
                fieldName: "file",
                originalName: fileURL.lastPathComponent,
                mimeType: "text/csv",
                data: fileData
            )
            let password = importSession.filePasswords[fileURL]
            let sealedPassword = try password.map { try ImportPasswordCrypto.seal($0) }
            let mutation = UploadStatementMutation(
                ledgerId: ledgerId.uuidString,
                file: "",
                password: sealedPassword.map {
                    .some(EncryptedPassword(ephemeralPublicKey: $0.ephemeralPublicKey, ciphertext: $0.ciphertext))
                } ?? .null
            )
            let response = try await graphQLClient.upload(mutation: mutation, files: [file])
            let result = response.uploadStatement
            totalInserted += result.imported
            totalSkipped += result.duplicates
            logger.logInfo("File uploaded: {imported} imported, {dups} duplicates", [
                "imported": result.imported,
                "dups": result.duplicates
            ])
        }
        return (totalInserted, totalSkipped)
    }
```
(same caveat as Step 4 about the exact generated `GraphQLNullable`-style
argument shape — verify against the real generated `UploadStatementMutation`
initializer).

- [ ] **Step 6: Write the failing regression test**

Create `Apps/FinanceOSMac/FinanceOSMacSnapshotTests/Flows/ImportViewModelPasswordTests.swift`:

```swift
import FinanceCore
@testable import FinanceOSMac
import Foundation
import XCTest

private actor FakeParser: StatementParsingProtocol {
    private var callCount = 0
    private let requiresPassword: Bool
    private let correctPassword: String

    init(requiresPassword: Bool, correctPassword: String = "secret123") {
        self.requiresPassword = requiresPassword
        self.correctPassword = correctPassword
    }

    func parse(fileURL: URL, password: String?) async throws -> ParsedStatement {
        callCount += 1
        if requiresPassword, password != correctPassword {
            throw TransactionImportError.passwordProtected(fileURL.lastPathComponent)
        }
        return ParsedStatement(bankName: "HDFC", accountName: "Test", accountLast4: "1234")
    }
}

private final class FakePasswordStore: ImportPasswordStoring {
    var savedPasswords: [UUID: String] = [:]

    func password(for ledgerId: UUID) -> String? {
        savedPasswords[ledgerId]
    }

    func save(_ password: String, for ledgerId: UUID) {
        savedPasswords[ledgerId] = password
    }
}

@MainActor
final class ImportViewModelPasswordTests: XCTestCase {
    func test_no_password_needed_parses_immediately() async throws {
        let viewModel = ImportViewModel(
            graphQLClient: ApolloGraphQLClient(),
            fileParser: FakeParser(requiresPassword: false)
        )
        let statement = try await viewModel.parseWithPasswordRetry(
            fileURL: URL(fileURLWithPath: "/tmp/statement.pdf"),
            parser: FakeParser(requiresPassword: false)
        )
        XCTAssertEqual(statement.bankName, "HDFC")
        XCTAssertNil(viewModel.pendingPasswordRequest)
    }

    func test_locked_file_prompts_then_resolves_on_correct_password() async throws {
        let viewModel = ImportViewModel(
            graphQLClient: ApolloGraphQLClient(),
            fileParser: FakeParser(requiresPassword: true)
        )
        let fileURL = URL(fileURLWithPath: "/tmp/statement.pdf")

        async let result = viewModel.parseWithPasswordRetry(fileURL: fileURL, parser: FakeParser(requiresPassword: true))

        // Wait for the prompt to appear, then submit the correct password.
        while viewModel.pendingPasswordRequest == nil {
            try await Task.sleep(for: .milliseconds(10))
        }
        let request = try XCTUnwrap(viewModel.pendingPasswordRequest)
        XCTAssertFalse(request.isRetry)
        request.onSubmit("secret123", false)

        let statement = try await result
        XCTAssertEqual(statement.bankName, "HDFC")
    }

    func test_wrong_password_reprompts_with_isRetry_true() async throws {
        let viewModel = ImportViewModel(
            graphQLClient: ApolloGraphQLClient(),
            fileParser: FakeParser(requiresPassword: true)
        )
        let fileURL = URL(fileURLWithPath: "/tmp/statement.pdf")

        async let result = viewModel.parseWithPasswordRetry(fileURL: fileURL, parser: FakeParser(requiresPassword: true))

        while viewModel.pendingPasswordRequest == nil {
            try await Task.sleep(for: .milliseconds(10))
        }
        viewModel.pendingPasswordRequest?.onSubmit("wrongpassword", false)

        while viewModel.pendingPasswordRequest == nil {
            try await Task.sleep(for: .milliseconds(10))
        }
        let retryRequest = try XCTUnwrap(viewModel.pendingPasswordRequest)
        XCTAssertTrue(retryRequest.isRetry)
        retryRequest.onSubmit("secret123", false)

        let statement = try await result
        XCTAssertEqual(statement.bankName, "HDFC")
    }

    func test_cancel_throws_passwordProtected() async {
        let viewModel = ImportViewModel(
            graphQLClient: ApolloGraphQLClient(),
            fileParser: FakeParser(requiresPassword: true)
        )
        let fileURL = URL(fileURLWithPath: "/tmp/statement.pdf")

        async let result: Void = {
            _ = try await viewModel.parseWithPasswordRetry(fileURL: fileURL, parser: FakeParser(requiresPassword: true))
        }()

        while viewModel.pendingPasswordRequest == nil {
            try? await Task.sleep(for: .milliseconds(10))
        }
        viewModel.pendingPasswordRequest?.onCancel()

        do {
            try await result
            XCTFail("expected passwordProtected to be thrown")
        } catch TransactionImportError.passwordProtected {
            // expected
        } catch {
            XCTFail("wrong error type: \(error)")
        }
    }

    func test_known_ledger_checks_keychain_before_prompting() async throws {
        let ledgerId = UUID()
        let passwordStore = FakePasswordStore()
        passwordStore.save("secret123", for: ledgerId)

        let viewModel = ImportViewModel(
            graphQLClient: ApolloGraphQLClient(),
            initialTarget: .ledger(ledgerId),
            fileParser: FakeParser(requiresPassword: true),
            passwordStore: passwordStore
        )
        let statement = try await viewModel.parseWithPasswordRetry(
            fileURL: URL(fileURLWithPath: "/tmp/statement.pdf"),
            parser: FakeParser(requiresPassword: true)
        )

        XCTAssertEqual(statement.bankName, "HDFC")
        XCTAssertNil(viewModel.pendingPasswordRequest, "should never have prompted — Keychain had it")
    }
}
```

- [ ] **Step 7: Run tests to verify they pass**

Run: `xcodebuild test -workspace FinanceOS.xcworkspace -scheme FinanceOSMac \
  -destination 'platform=macOS,arch=arm64' \
  -only-testing:FinanceOSMacSnapshotTests/ImportViewModelPasswordTests`
Expected: 5 tests pass

- [ ] **Step 8: Run the full existing import test suite for regressions**

Run: `xcodebuild test -workspace FinanceOS.xcworkspace -scheme FinanceOSMac \
  -destination 'platform=macOS,arch=arm64' \
  -only-testing:FinanceOSMacSnapshotTests/ImportFlowSnapshotTests \
  -only-testing:FinanceOSMacSnapshotTests/ImportTargetSectionSnapshotTests \
  -only-testing:FinanceOSMacSnapshotTests/ImportViewModelStateManagementTests`
Expected: all pass (these exercise the same `parseFiles()`/`autoSelectMatchingTarget()`
code paths from the single-screen-import-flow branch — confirm nothing broke).

- [ ] **Step 9: Lint and commit**

Run: `swiftlint lint --strict --quiet`
Expected: no output

```bash
git add Apps/FinanceOSMac/GraphQL/Operations/Mutations.graphql \
  Apps/FinanceOSMac/GraphQL/schema.graphql Apps/FinanceOSMac/GraphQL/Generated/ \
  Packages/FinanceCore/Sources/FinanceCore/Importing/TransactionImportError.swift \
  Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportSession.swift \
  Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportViewModel.swift \
  Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportViewModelStateManagement.swift \
  Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/Services/ImportFileParser.swift \
  Apps/FinanceOSMac/FinanceOSMacSnapshotTests/Flows/ImportViewModelPasswordTests.swift
git commit -m "feat(import): wire password-retry loop into ImportViewModel"
```

---

## Task 8: Swift — `PasswordPromptSheet` wiring + `SheetRoute` cleanup

**Repo:** `FinanceOS`

**Files:**
- Modify: `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportView.swift`
- Modify: `Apps/FinanceOSMac/FinanceOSMac/Presentation/Navigation/SheetRoute.swift`
- Test: `Apps/FinanceOSMac/FinanceOSMacSnapshotTests/Flows/PasswordPromptSheetSnapshotTests.swift`

**Interfaces:**
- Consumes: `ImportViewModel.pendingPasswordRequest: PasswordPromptRequest?` (Task 7).

- [ ] **Step 1: Write the failing snapshot tests (currently zero coverage)**

Create `Apps/FinanceOSMac/FinanceOSMacSnapshotTests/Flows/PasswordPromptSheetSnapshotTests.swift`:

```swift
@testable import FinanceOSMac
import SnapshotTesting
import SwiftUI
import XCTest

final class PasswordPromptSheetSnapshotTests: SnapshotTestable {
    override var record: Bool { false }

    func test_password_prompt_initial() {
        let view = PasswordPromptSheet(
            filename: "hdfc_statement.pdf",
            isPasswordInvalid: false,
            onCancel: {},
            onSubmit: { _, _ in }
        )
        verifySnapshots(view)
    }

    func test_password_prompt_invalid() {
        let view = PasswordPromptSheet(
            filename: "hdfc_statement.pdf",
            isPasswordInvalid: true,
            onCancel: {},
            onSubmit: { _, _ in }
        )
        verifySnapshots(view)
    }
}
```

- [ ] **Step 2: Run test to verify it fails (no reference snapshot yet)**

Run: `xcodebuild test -workspace FinanceOS.xcworkspace -scheme FinanceOSMac \
  -destination 'platform=macOS,arch=arm64' \
  -only-testing:FinanceOSMacSnapshotTests/PasswordPromptSheetSnapshotTests`
Expected: FAIL — no reference image exists yet

- [ ] **Step 3: Record the reference snapshots**

Temporarily change `override var record: Bool { false }` to `{ true }` in
the test file, run the same command once to record, then change it back to
`{ false }` (matching every other snapshot test file in this target —
confirm this is the actual recording mechanism by checking how
`ImportTargetSectionSnapshotTests` or `ImportFlowSnapshotTests` were
originally recorded, e.g. via `git log -p` on those files' first commit, in
case this repo uses a different recording convention — e.g. an environment
variable instead of the `record` override).

Run: `xcodebuild test ... -only-testing:FinanceOSMacSnapshotTests/PasswordPromptSheetSnapshotTests`
(with `record` temporarily `true`)
Expected: writes 2 new PNGs under
`Apps/FinanceOSMac/FinanceOSMacSnapshotTests/Flows/__Snapshots__/PasswordPromptSheetSnapshotTests/`

Revert `record` to `false`, run again.
Expected: 2 tests pass against the newly recorded references.

- [ ] **Step 4: Wire the sheet into `ImportView`**

Read `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportView.swift`
in full first (shown earlier this session — the `onAppear` block reading
`navigator.pendingImportTarget` is the relevant anchor). Add a `.sheet(item:)`
modifier bound to the view model's `pendingPasswordRequest`, following the
same local-state pattern `ImportTargetSection` uses for
`sheetCreationItem` (not the global `SheetRoute` switch):

```swift
        .sheet(item: $viewModel.pendingPasswordRequest) { request in
            PasswordPromptSheet(
                filename: request.filename,
                isPasswordInvalid: request.isRetry,
                onCancel: request.onCancel,
                onSubmit: request.onSubmit
            )
        }
```
Add this modifier to the same `VStack` chain as the existing `.onAppear`/
`.onChange`/`.animation` modifiers in `ImportView.body` — order relative to
those doesn't matter since they act on independent state.

`PasswordPromptRequest` needs `Identifiable` for `.sheet(item:)` — it
already declared `let id = UUID()` in Task 7, so no further change needed
there.

- [ ] **Step 5: Delete the dead `SheetRoute.passwordPrompt` case**

Modify `Apps/FinanceOSMac/FinanceOSMac/Presentation/Navigation/SheetRoute.swift` —
remove the `case passwordPrompt` line and its corresponding `case
.passwordPrompt: "password"` branch in the `id` computed property (confirmed
in this session's earlier investigation that nothing renders this case
today — it's dead scaffold, and the local `.sheet(item:)` pattern from Step 4
is how this codebase actually handles per-instance callback-driven sheets).

- [ ] **Step 6: Run the full Import test suite**

Run: `xcodebuild test -workspace FinanceOS.xcworkspace -scheme FinanceOSMac \
  -destination 'platform=macOS,arch=arm64' \
  -only-testing:FinanceOSMacSnapshotTests/ImportFlowSnapshotTests \
  -only-testing:FinanceOSMacSnapshotTests/ImportTargetSectionSnapshotTests \
  -only-testing:FinanceOSMacSnapshotTests/ImportViewModelStateManagementTests \
  -only-testing:FinanceOSMacSnapshotTests/ImportViewModelPasswordTests \
  -only-testing:FinanceOSMacSnapshotTests/ImportPasswordCryptoTests \
  -only-testing:FinanceOSMacSnapshotTests/ImportPasswordStoreTests \
  -only-testing:FinanceOSMacSnapshotTests/PasswordPromptSheetSnapshotTests`
Expected: all pass

- [ ] **Step 7: Full build**

Run: `xcodebuild build \
  -workspace FinanceOS.xcworkspace \
  -scheme FinanceOSMac \
  -destination 'platform=macOS,arch=arm64' \
  COMPILER_INDEX_STORE_ENABLE=NO \
  -quiet 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 8: Lint and commit**

Run: `swiftlint lint --strict --quiet`
Expected: no output

```bash
git add Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportView.swift \
  Apps/FinanceOSMac/FinanceOSMac/Presentation/Navigation/SheetRoute.swift \
  Apps/FinanceOSMac/FinanceOSMacSnapshotTests/Flows/PasswordPromptSheetSnapshotTests.swift \
  Apps/FinanceOSMac/FinanceOSMacSnapshotTests/Flows/__Snapshots__/PasswordPromptSheetSnapshotTests/
git commit -m "feat(import): wire PasswordPromptSheet into ImportView, delete dead SheetRoute case"
```

- [ ] **Step 9: Manual verification**

Per the spec's Testing section: with a live local backend (Tasks 1–4
deployed), drag a real password-protected HDFC or ICICI PDF statement onto
the import screen. Confirm: the prompt appears, entering the wrong password
re-prompts with the "incorrect" state, the correct password proceeds to
`.readyToImport`, and — if "Save to Keychain" was checked — importing a
second statement for the same ledger doesn't re-prompt.

---
