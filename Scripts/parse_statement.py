"""
HDFC Bank Statement Parser
Parses the fixed-width CSV text statement format exported by HDFC NetBanking.

Usage:
    python parse_statement.py                          # parses default file, prints summary
    python parse_statement.py statement.txt            # custom file path
    python parse_statement.py statement.txt out.csv    # also exports to CSV
"""

import csv
import sys
from dataclasses import dataclass, fields, astuple
from datetime import datetime
from pathlib import Path
from typing import Optional


# ── Data model ────────────────────────────────────────────────────────────────

@dataclass
class Transaction:
    date: datetime
    narration: str
    value_date: datetime
    debit: float
    credit: float
    chq_ref: str
    closing_balance: float

    # Derived helpers (not stored in CSV export)
    @property
    def amount(self) -> float:
        """Signed amount: positive = credit, negative = debit."""
        return self.credit - self.debit

    @property
    def type(self) -> str:
        return "CR" if self.credit > 0 else "DR"

    @property
    def counterparty(self) -> Optional[str]:
        """Best-effort extraction of the other party's name from the narration."""
        n = self.narration.strip()
        if n.startswith("UPI-"):
            # UPI-NAME-upi_handle-... or UPI-NAME@handle-...
            parts = n[4:].split("-")
            return parts[0].strip().title() if parts else None
        if n.startswith("NEFT CR-") or n.startswith("NEFT DR-"):
            # NEFT CR-BANKCODE-SENDER NAME-CITY-REF
            parts = n.split("-")
            return parts[2].strip().title() if len(parts) > 2 else None
        if n.startswith("IMPS-"):
            parts = n.split("-")
            return parts[2].strip().title() if len(parts) > 2 else None
        if n.startswith("TP-"):
            parts = n.split("-")
            return parts[1].strip().title() if len(parts) > 1 else None
        if n.startswith("ACH"):
            return "ACH Direct Debit"
        if n.startswith("IB BILLPAY"):
            return "Bill Payment"
        if "INTEREST PAID" in n:
            return "Bank Interest"
        return None

    @property
    def category(self) -> str:
        """Rule-based category tagging."""
        n = self.narration.upper()
        if "SALARY" in n or "PAYPAL INDIA" in n:
            return "salary"
        if "INW " in n or "INWARD" in n:
            return "forex_inward"
        if "CRED" in n and ("PAYMENT ON CRED" in n or "CREDCLUB" in n or "CCBP" in n):
            return "credit_card_repayment"
        if "AMERICAN EXPRESS" in n or "AEBC" in n:
            return "credit_card_repayment"
        if "MAX LIFE" in n or "MAX LIFE INS" in n:
            return "insurance"
        if "AIRTEL" in n:
            return "telecom"
        if "SPOTIFY" in n:
            return "subscription"
        if "APPLE" in n:
            return "subscription"
        if "BLINKIT" in n or "ZOMATO" in n or "DOMINOS" in n or "SWIGGY" in n:
            return "food_delivery"
        if "HEMA GROCERY" in n or "BIGBASKET" in n or "BBNOW" in n:
            return "groceries"
        if "SEEMA GOEL" in n and "RENT" in n:
            return "rent"
        if "RITIK GUPTA" in n:
            return "rent"
        if "TDS" in n or "TDS FOR RENT" in n:
            return "rent_tds"
        if "EDU LOAN" in n or "PUNB0023310" in n:
            return "education_loan"
        if "SIP" in n or "MUTUAL FUND" in n or "GROWW" in n or "ICCL" in n:
            return "investment"
        if "APOLLO PHARMACY" in n or "PHARMACY" in n:
            return "healthcare"
        if "LOMBARD" in n:
            return "insurance_claim"
        if "INTEREST PAID" in n:
            return "bank_interest"
        if "BILLPAY" in n or "IB BILLPAY" in n:
            return "bill_payment"
        if "H AND M" in n or "HENNES" in n or "IKEA" in n:
            return "shopping"
        if "RAILWAYS" in n or "INDIAN RAILWAYS" in n:
            return "travel"
        if "VIRGIN ATLANTIC" in n:
            return "travel_refund"
        if self.credit > 0:
            return "other_credit"
        return "other_debit"


# ── Parser ─────────────────────────────────────────────────────────────────────

def parse_date(s: str) -> datetime:
    s = s.strip()
    for fmt in ("%d/%m/%y", "%d/%m/%Y"):
        try:
            return datetime.strptime(s, fmt)
        except ValueError:
            continue
    raise ValueError(f"Cannot parse date: {s!r}")


def parse_amount(s: str) -> float:
    return float(s.strip().replace(",", "") or "0")


def parse_statement(filepath: str | Path) -> list[Transaction]:
    """
    Parse an HDFC bank statement text file and return a list of Transaction objects.

    The file format is a comma-delimited text with fixed-width padding:
        Date, Narration, Value Date, Debit Amount, Credit Amount, Chq/Ref Number, Closing Balance
    The header line is line 2 (line 1 is blank).
    """
    path = Path(filepath)
    if not path.exists():
        raise FileNotFoundError(f"File not found: {path}")

    transactions: list[Transaction] = []
    skipped = 0

    with path.open(encoding="utf-8", errors="replace") as fh:
        for lineno, raw in enumerate(fh, start=1):
            line = raw.rstrip("\n")

            # Skip blank lines and the header row
            stripped = line.strip()
            if not stripped or stripped.startswith("Date"):
                continue

            parts = line.split(",")
            if len(parts) < 7:
                skipped += 1
                continue

            # The format has exactly 7 logical columns. When the narration
            # field contains commas (rare) OR when a NEFT narration with
            # hyphens causes an off-by-one split, we reconstruct by anchoring
            # on the last 4 columns (amounts + ref + balance), which are
            # always numeric/fixed-width, and treating everything in between
            # as the narration.
            try:
                date_str = parts[0]
                value_date_str = parts[2]
                debit_str = parts[3]
                credit_str = parts[4]
                chq_str = parts[5]
                balance_str = parts[6]

                # Validate that the "value date" field at index 2 actually
                # looks like a date; if not, the narration itself contained
                # commas and we need to re-anchor from the right.
                try:
                    parse_date(value_date_str)
                except ValueError:
                    # Re-anchor: last 4 cols are debit, credit, chq, balance.
                    # Second-to-last group before those is value_date.
                    # Everything from index 1 up to value_date is narration.
                    # Find the rightmost valid date scanning backward from end.
                    anchor = None
                    for i in range(len(parts) - 4, 1, -1):
                        try:
                            parse_date(parts[i])
                            anchor = i
                            break
                        except ValueError:
                            continue
                    if anchor is None:
                        raise ValueError(f"Cannot locate value_date in line")
                    value_date_str = parts[anchor]
                    debit_str = parts[anchor + 1]
                    credit_str = parts[anchor + 2]
                    chq_str = parts[anchor + 3]
                    balance_str = parts[anchor + 4]
                    # Narration = everything between index 1 and anchor (exclusive)
                    narration = ",".join(parts[1:anchor]).strip()
                else:
                    narration = parts[1].strip()

                txn = Transaction(
                    date=parse_date(date_str),
                    narration=narration,
                    value_date=parse_date(value_date_str),
                    debit=parse_amount(debit_str),
                    credit=parse_amount(credit_str),
                    chq_ref=chq_str.strip(),
                    closing_balance=parse_amount(balance_str),
                )
                transactions.append(txn)
            except (ValueError, IndexError) as e:
                skipped += 1
                print(f"  [line {lineno}] skipped — {e}", file=sys.stderr)

    if skipped:
        print(f"Warning: {skipped} line(s) could not be parsed.", file=sys.stderr)

    # Sort chronologically (file is usually already sorted, but just in case)
    transactions.sort(key=lambda t: t.date)
    return transactions


# ── Export ─────────────────────────────────────────────────────────────────────

EXPORT_HEADERS = [
    "date", "value_date", "type", "amount", "debit", "credit",
    "closing_balance", "category", "counterparty", "narration", "chq_ref",
]


def export_csv(transactions: list[Transaction], out_path: str | Path) -> None:
    """Export parsed transactions to a clean CSV file."""
    out = Path(out_path)
    with out.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=EXPORT_HEADERS)
        writer.writeheader()
        for t in transactions:
            writer.writerow({
                "date": t.date.strftime("%Y-%m-%d"),
                "value_date": t.value_date.strftime("%Y-%m-%d"),
                "type": t.type,
                "amount": round(t.amount, 2),
                "debit": t.debit,
                "credit": t.credit,
                "closing_balance": t.closing_balance,
                "category": t.category,
                "counterparty": t.counterparty or "",
                "narration": t.narration,
                "chq_ref": t.chq_ref,
            })
    print(f"Exported {len(transactions)} transactions → {out}")


# ── Summary ────────────────────────────────────────────────────────────────────

def print_summary(transactions: list[Transaction]) -> None:
    if not transactions:
        print("No transactions found.")
        return

    total_credit = sum(t.credit for t in transactions)
    total_debit = sum(t.debit for t in transactions)
    opening = transactions[0].closing_balance - transactions[0].amount
    closing = transactions[-1].closing_balance

    print("\n" + "=" * 55)
    print("  STATEMENT SUMMARY")
    print("=" * 55)
    print(f"  Period          : {transactions[0].date:%d %b %Y} – {transactions[-1].date:%d %b %Y}")
    print(f"  Transactions    : {len(transactions)}")
    print(f"  Opening balance : ₹{opening:>12,.2f}")
    print(f"  Total credits   : ₹{total_credit:>12,.2f}")
    print(f"  Total debits    : ₹{total_debit:>12,.2f}")
    print(f"  Net flow        : ₹{total_credit - total_debit:>12,.2f}")
    print(f"  Closing balance : ₹{closing:>12,.2f}")

    # Category breakdown
    from collections import defaultdict
    cat_totals: dict[str, float] = defaultdict(float)
    for t in transactions:
        if t.debit > 0:
            cat_totals[t.category] += t.debit

    print("\n  Top debit categories:")
    for cat, amt in sorted(cat_totals.items(), key=lambda x: -x[1])[:10]:
        print(f"    {cat:<30} ₹{amt:>10,.0f}")
    print("=" * 55 + "\n")


# ── CLI entry point ────────────────────────────────────────────────────────────

if __name__ == "__main__":
    input_file = sys.argv[1] if len(sys.argv) > 1 else "Acct_Statement_XXXXXXXX6521_15052026.txt"
    output_file = sys.argv[2] if len(sys.argv) > 2 else None

    print(f"Parsing: {input_file}")
    txns = parse_statement(input_file)
    print(f"Parsed {len(txns)} transactions.")

    print_summary(txns)

    if output_file:
        export_csv(txns, output_file)
    else:
        # Default: export alongside the input file
        default_out = Path(input_file).with_suffix(".parsed.csv")
        export_csv(txns, default_out)
