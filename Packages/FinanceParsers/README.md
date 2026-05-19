# FinanceParsers

Standalone, headless bank statement parsing library for HDFC, ICICI, Amex, and Scapia.

## Quick Start

### Build

```bash
cd Packages/FinanceParsers
swift build
```

### Parse a PDF

```bash
swift run FinanceParserCLI parse ~/Documents/statement.pdf
```

Output: normalized JSON with transactions

### Test with Fixtures

```bash
swift test -v
```

## Using with Make

From repo root:

```bash
make parser-test          # Run tests
make parser-parse FILE=path/to/file.pdf  # Parse file
make parser-clean         # Clean build
```

## Using with Script

```bash
./scripts/test_parser.sh ~/Documents/Acct_Statement_XXXXXXXX6521_15052026.pdf
```

## Password-Protected PDFs

```bash
swift run FinanceParserCLI parse statement.pdf --password "YOUR_PASSWORD"
```

## Library Usage

```swift
import FinanceParsers

let parser = HDFCPDFParser(password: nil)
let statement = try await parser.parseStatement(from: fileURL)

for txn in statement.transactions {
    print("\(txn.postedAt) | \(txn.description) | \(txn.amountMinorUnits)")
}
```

## Architecture

- `StatementParser`: Protocol for format-specific parsers
- `HDFCPDFParser`: PDF statement extraction
- `HDFCLineClassifier`: Boilerplate + line purpose detection
- `HDFCTransactionReconstructor`: Multiline transaction assembly
- `HDFCTransactionParser`: Transaction extraction + validation
- `FinanceParserCLI`: CLI harness for testing

## Fixtures

Add statement files to `Fixtures/HDFC/` for testing:

```
Fixtures/
  HDFC/
    statement-2025-04.pdf
    statement-2025-05.pdf
```

Tests automatically discover and parse all fixtures.

## Output Format

JSON schema:

```json
{
  "bankName": "HDFC",
  "accountName": "Unknown",
  "statementPeriodStart": "2025-04-01T00:00:00Z",
  "statementPeriodEnd": "2025-03-31T00:00:00Z",
  "currency": "INR",
  "totalDebit": 1000000,
  "totalCredit": 5000000,
  "transactions": [
    {
      "id": "UUID",
      "postedAt": "2025-04-01T00:00:00Z",
      "description": "UPI-BANK",
      "amountMinorUnits": -250000,
      "currencyCode": "INR",
      "sourceFingerprint": "hash",
      "rewardPoints": null
    }
  ]
}
```

## Next: Python Reference

Add Python extraction scripts for comparison:

```bash
python3 scripts/extract_hdfc_pdf.py statement.pdf
```

Then compare outputs:

```bash
python3 scripts/compare_parsers.py statement.pdf
```
