#!/usr/bin/env python3
"""
FinanceOS Category Classifier Training Pipeline.

Parses HDFC / ICICI / Amex / Scapia statements, applies labeling rules,
trains a DictVectorizer + LogisticRegression classifier, and exports:

  ml_output/training-category.json              → CreateML Text Classifier (NLModel path)
  ml_output/TransactionCategoryClassifier.mlmodel → CoreML via sklearn (MLModel path)
  ml_output/evaluation-report.txt               → per-class metrics

Usage:
    python3 Scripts/train_category_classifier.py

Requirements: scikit-learn, coremltools, numpy (all installed via brew/pip)
"""

from __future__ import annotations

import csv
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import NamedTuple

import numpy as np

# ─── Paths ────────────────────────────────────────────────────────────────────

SOURCES = {
    "amex":   Path("/Users/pragoel/Documents/Amex"),
    "hdfc":   Path("/Users/pragoel/Documents/HDFC"),
    "icici":  Path("/Users/pragoel/Documents/ICICI"),
    "scapia": Path("/Users/pragoel/Documents/Scapia"),
}
REPO_ROOT  = Path(__file__).resolve().parent.parent
OUT_DIR    = REPO_ROOT / "Scripts" / "ml_output"
RESOURCES  = (REPO_ROOT / "Packages" / "FinanceIntelligence" /
              "Sources" / "FinanceIntelligence" / "Resources")

MIN_PER_CLASS = 5
MAX_PER_CLASS = 250  # cap dominant classes

# ─── Data model ───────────────────────────────────────────────────────────────

class Transaction(NamedTuple):
    narration: str
    text: str        # cleaned, PII-stripped
    amount: float
    is_debit: bool
    source: str
    label: str | None = None

# ─── Text cleaning ────────────────────────────────────────────────────────────

_REF    = re.compile(r'\b\d{6,}\b')
_ACCT   = re.compile(r'\b[X]{4,}[0-9A-Z]*\b', re.I)
_UPI    = re.compile(r'[A-Z0-9._+%-]+@[A-Z0-9]+', re.I)
_TIME   = re.compile(r'\b\d{2}:\d{2}:\d{2}\b')
_MULTI  = re.compile(r'\s{2,}')

_STRIP_PREFIXES = (
    'NEFT ', 'IMPS-', 'IMPS/', 'UPI-', 'UPI/', 'ACH ', 'NACH ',
    'BBPS ', 'BIL/', 'INW ', 'ECSRTN', 'INFT/', 'TPT-', 'REF# ',
    'ICICN', 'HDFCH', 'BOFAN', 'BOFAH', 'CITIN', 'SCBL',
)

def clean_text(narration: str) -> str:
    t = narration.upper()
    t = _TIME.sub(' ', t)
    t = _ACCT.sub(' ', t)
    t = _UPI.sub(' ', t)
    t = _REF.sub(' ', t)
    for pfx in _STRIP_PREFIXES:
        t = t.replace(pfx, ' ')
    return _MULTI.sub(' ', t).strip()

# ─── Labeling rules ───────────────────────────────────────────────────────────
# First match wins — keep specific patterns before broad ones.

_RULES: list[tuple[str, str]] = [
    # Income
    (r'salary|payroll',                                                'income.salary'),
    (r'inward remittance|inw |fcy credit|usd.*@|foreign.*inward',      'income.salary'),
    (r'paypal india|bofa.*paypal|paypal.*salary',                       'income.salary'),
    (r'int(?:erest)?.?(?:paid|earned|on deposit)|int\.pd',             'income.interest'),
    (r'dividend',                                                        'income.dividend'),
    (r'insurance.*claim|refund from|cashback.*credit',                  'income.refund'),
    (r'icici lombard.*credit|neft cr.*icici lombard',                   'income.refund'),

    # Taxes
    (r'\bigst\b|\bcgst\b|\bsgst\b|tax deducted|tds\b|income.*tax|dpo\d', 'taxes'),

    # Insurance
    (r'lic \b|life insurance corp|lic of india',                        'insurance.life'),
    (r'max life|hdfc life|bajaj allianz life|sbi life|tata aia',        'insurance.life'),
    (r'icici lombard|star health|niva bupa|care health|hdfc ergo',      'insurance.health'),

    # Investments
    (r'zerodha|groww|kuvera|paytm money|angel.*broking|upstox',        'investments.stocks'),
    (r'indian clearing corp|bse limit|nse clear',                       'investments.sip'),
    (r'ppf a/c|public provident',                                       'investments.fd'),
    (r'fixed deposit|fd.*open|fd.*renew',                              'investments.fd'),

    # Housing
    (r'ritik gupta|ritikgupta|rent.*1804|mana capitol',                 'housing.rent'),
    (r'house.*rent|monthly.*rent|rent.*paid|rental.*payment',           'housing.rent'),
    (r'maintenance.*fee|society.*fee|apartment.*fee',                   'housing.maintenance'),

    # Groceries
    (r'zepto|blinkit|bigbasket|jiomart|grofers|nature.s basket|dmart',  'groceries'),
    (r'reliance fresh|more supermarket|spencer|hypercity',              'groceries'),
    (r'instacart|whole foods|trader joe|kroger|safeway|costco',         'groceries'),

    # Food delivery
    (r'swiggy(?!.*instamart)',                                          'dining.delivery'),
    (r'zomato',                                                          'dining.delivery'),
    (r'dunzo',                                                           'dining.delivery'),
    (r'uber eats|doordash|grubhub',                                     'dining.delivery'),

    # Coffee / cafes
    (r'starbucks|cafe coffee day|barista|chaayos|third wave|coffe and more', 'dining.coffee'),
    (r'costa coffee|blue tokai|tim hortons',                            'dining.coffee'),

    # Restaurants
    (r'mcdonald|kfc\b|burger king|pizza hut|dominos|subway\b|taco bell', 'dining.restaurant'),
    (r'haldiram|biryani blues|fassos|wow momo|barbeque nation|social\b', 'dining.restaurant'),
    (r'moon light boarding|platos foods',                               'dining.restaurant'),

    # Travel - flights
    (r'indigo|air india|spicejet|vistara|akasa|bluejet',               'travel.flight'),
    (r'etihad|emirates|british airways|lufthansa|qatar|united airlines', 'travel.flight'),
    (r'virgin atlantic',                                                 'travel.flight'),
    (r'irctc|indian railways|train.*ticket',                            'travel'),
    (r'oyo.*room|taj hotel|marriott|hyatt|hilton|radisson|ibis',       'travel.hotel'),
    (r'makemytrip|mmt\b|goibibo|cleartrip|ixigo|yatra',               'travel'),

    # Transport
    (r'uber(?!.*eats)',                                                  'transportation.rideshare'),
    (r'\bola\b|rapido|meru|savaari',                                    'transportation.rideshare'),
    (r'metro.*card|bmtc|nmmt|dtc\b|ksrtc|best bus',                   'transportation.transit'),
    (r'fastag|netc.*fastag|toll',                                       'transportation'),
    (r'petrol|ioc\b|hpcl|bpcl|shell\b|fuel.*station',                 'transportation.fuel'),

    # Subscriptions
    (r'netflix',                                                         'subscriptions.streaming'),
    (r'hotstar|disney\+|jio cinema|sony liv|zee5|voot',                'subscriptions.streaming'),
    (r'amazon prime|prime video',                                       'subscriptions.streaming'),
    (r'spotify',                                                         'subscriptions.music'),
    (r'apple music|amazon music|wynk|gaana|jio saavn',                 'subscriptions.music'),
    (r'apple.*india|appleindiapvt|app.*store',                         'subscriptions.software'),
    (r'youtube.*premium|youtube.*subscri|google.*one\b',               'subscriptions.software'),
    (r'microsoft.*365|adobe.*subscri|notion\.so|slack\b|zoom\b',      'subscriptions.software'),
    (r'instacart.*subscri',                                             'subscriptions.software'),
    (r'linkedin.*premium',                                              'subscriptions'),

    # Shopping
    (r'amazon(?!.*prime|.*received)',                                   'shopping.online'),
    (r'flipkart',                                                        'shopping.online'),
    (r'myntra|payumyntra|payu.*myntra|ajio',                           'shopping.clothing'),
    (r'nykaa|nysaa',                                                    'shopping'),
    (r'meesho|tata cliq|snapdeal',                                     'shopping.online'),
    (r'giva\b|tanishq|kalyan jeweller|malabar|senco',                  'shopping'),
    (r'croma|vijay sales|reliance digital',                             'shopping.online'),
    (r'decathlon|nike\b|adidas|puma\b|zara\b|h&m\b',                  'shopping.clothing'),

    # Utilities
    (r'airtel(?!.*dth)',                                                 'utilities.phone'),
    (r'jio(?!.*cinema|.*saavn)',                                        'utilities.phone'),
    (r'\bvi\b|vodafone|bsnl\b|tata teleservices',                      'utilities.phone'),
    (r'bescom|bses|tpddl|msedcl|tneb|electricity board|adani elec',   'utilities.electricity'),
    (r'bwssb|water board|jal board',                                   'utilities.water'),
    (r'tata play|dish tv|d2h\b|airtel dth|sun direct',                'utilities'),
    (r'act fibernet|hathway|you broadband|tikona|excitel',             'utilities.internet'),
    (r'piped gas|mahanagar gas|indraprastha gas|adani gas',            'utilities.gas'),

    # Healthcare
    (r'pharmeasy|netmeds|1mg\b|medplus|apollo.*pharmac|wellness forever', 'healthcare.pharmacy'),
    (r'apollo hospital|fortis|manipal hospital|narayana health|max hospital', 'healthcare.doctor'),
    (r'cult\.fit|curefit|healthkart',                                  'healthcare'),

    # Fees
    (r'cred\b|cred club',                                               'fees'),
    (r'annual.*fee|joining.*fee|membership.*fee|renewal.*fee',          'fees'),
    (r'late.*fee|overdue|penalty|finance charge|overlimit',             'fees'),
    (r'sms.*chg|sms.*charge|processing.*fee|service.*chg|bank.*chg',   'fees'),

    # Transfers (broad — catches remainder)
    (r'payment received|payment.*thank you|credit card.*payment|bppy cc', 'transfers'),
    (r'self.*transfer|internal.*transfer',                              'transfers.internal'),
    (r'indian clearing|settlement|ecs.*return|nach.*return|ecsrtn',    'transfers'),
    (r'seema goel|sailesh.*goel',                                       'transfers.external'),
]

_COMPILED = [(re.compile(p, re.I), lbl) for p, lbl in _RULES]

_DEBIT_ONLY = {
    'groceries', 'dining.delivery', 'dining.coffee', 'dining.restaurant',
    'travel.flight', 'travel.hotel', 'travel', 'transportation.rideshare',
    'transportation.transit', 'transportation.fuel', 'transportation',
    'subscriptions.streaming', 'subscriptions.music', 'subscriptions.software',
    'subscriptions', 'shopping.online', 'shopping.clothing', 'shopping',
    'utilities.phone', 'utilities.electricity', 'utilities.water',
    'utilities.internet', 'utilities.gas', 'utilities',
    'healthcare.pharmacy', 'healthcare.doctor', 'healthcare',
    'insurance.life', 'insurance.health', 'insurance',
    'investments.stocks', 'investments.sip', 'investments.fd',
    'housing.rent', 'housing.maintenance', 'fees', 'taxes',
}

def label(narration: str, text: str, is_debit: bool) -> str | None:
    combined = narration + ' ' + text
    for pattern, lbl in _COMPILED:
        if pattern.search(combined):
            if not is_debit and lbl in _DEBIT_ONLY:
                continue
            return lbl
    return None

# ─── Parsers ──────────────────────────────────────────────────────────────────

def parse_amex(path: Path) -> list[Transaction]:
    txns = []
    with open(path, newline='', encoding='utf-8-sig', errors='replace') as f:
        for row in csv.DictReader(f):
            desc = row.get('Description', '').strip()
            try:
                amt = float(row['Amount'].replace(',', ''))
            except (ValueError, KeyError):
                continue
            if not desc or 'PAYMENT RECEIVED' in desc.upper():
                continue
            is_debit = amt > 0
            txns.append(Transaction(desc, clean_text(desc), abs(amt), is_debit, 'amex'))
    return txns


def parse_hdfc_debit_txt(path: Path) -> list[Transaction]:
    txns = []
    with open(path, newline='', encoding='utf-8-sig', errors='replace') as f:
        for row in csv.reader(f):
            if len(row) < 5:
                continue
            narr = row[1].strip()
            if not narr or narr.lower().startswith('narration'):
                continue
            try:
                debit  = float(row[3].strip().replace(',', '') or '0')
                credit = float(row[4].strip().replace(',', '') or '0')
            except ValueError:
                continue
            if debit == 0 and credit == 0:
                continue
            is_debit = debit > 0
            txns.append(Transaction(narr, clean_text(narr), debit or credit, is_debit, 'hdfc_debit'))
    return txns


def parse_hdfc_credit_billing(path: Path) -> list[Transaction]:
    """HDFC credit card: ~|~ delimiter, 7 columns after the header row."""
    txns = []
    in_data = False
    with open(path, encoding='utf-8-sig', errors='replace') as f:
        for line in f:
            if 'Transaction type' in line and 'Description' in line:
                in_data = True
                continue
            if not in_data:
                continue
            parts = [p.strip() for p in line.split('~|~')]
            if len(parts) < 5 or not parts[3]:
                continue
            try:
                amt = float(parts[4].replace(',', '').replace(' ', ''))
            except ValueError:
                continue
            is_credit = len(parts) > 5 and parts[5].strip().upper() == 'CR'
            desc = parts[3]
            txns.append(Transaction(desc, clean_text(desc), amt, not is_credit, 'hdfc_credit'))
    return txns


def parse_icici_credit(path: Path, source: str) -> list[Transaction]:
    """ICICI credit card: quoted CSV, data starts after 'Transaction Details' header row."""
    txns = []
    in_data = False
    with open(path, newline='', encoding='utf-8-sig', errors='replace') as f:
        for row in csv.reader(f):
            if not row:
                continue
            joined = ','.join(row)
            if 'Transaction Details' in joined and 'Amount' in joined:
                in_data = True
                continue
            if not in_data or len(row) < 6:
                continue
            if re.match(r'^[0-9X]{14,}$', row[0].strip()):
                continue  # card number row
            desc = row[2].strip() if len(row) > 2 else ''
            if len(desc) < 3:
                continue
            try:
                amt = float(row[5].replace(',', '')) if row[5].strip() else 0
            except (ValueError, IndexError):
                continue
            if amt == 0:
                continue
            is_credit = len(row) > 6 and row[6].strip().upper() == 'CR'
            txns.append(Transaction(desc, clean_text(desc), amt, not is_credit, source))
    return txns


def parse_icici_savings(path: Path) -> list[Transaction]:
    """ICICI savings: DATE,MODE,PARTICULARS,DEPOSITS,WITHDRAWALS,BALANCE (multi-section)."""
    txns = []
    in_data = False
    with open(path, newline='', encoding='utf-8-sig', errors='replace') as f:
        for row in csv.reader(f):
            if not row:
                in_data = False
                continue
            if row[0].strip() == 'DATE' and len(row) >= 5 and 'PARTICULARS' in ','.join(row):
                in_data = True
                continue
            if not in_data or len(row) < 5:
                continue
            if not re.match(r'\d{2}-\d{2}-\d{4}', row[0].strip()):
                continue
            particulars = row[2].strip()
            if not particulars:
                continue
            try:
                deposits    = float(row[3].replace(',', '') or '0')
                withdrawals = float(row[4].replace(',', '') or '0')
            except ValueError:
                continue
            if deposits == 0 and withdrawals == 0:
                continue
            is_debit = withdrawals > 0
            txns.append(Transaction(particulars, clean_text(particulars),
                                    withdrawals or deposits, is_debit, 'icici_savings'))
    return txns


# ─── Dataset assembly ─────────────────────────────────────────────────────────

def load_all() -> list[Transaction]:
    all_txns: list[Transaction] = []

    def add(lst): all_txns.extend(lst)

    # Amex
    for f in sorted(SOURCES['amex'].glob('*.[Cc][Ss][Vv]')):
        add(parse_amex(f))

    # HDFC debit TXT files (root and Excel subdir)
    for f in sorted(SOURCES['hdfc'].glob('*.[Tt][Xx][Tt]')):
        add(parse_hdfc_debit_txt(f))
    for f in sorted((SOURCES['hdfc'] / 'Excel').glob('*.[Tt][Xx][Tt]')):
        add(parse_hdfc_debit_txt(f))

    # HDFC credit billing CSVs
    for f in sorted((SOURCES['hdfc'] / 'Excel').glob('*.[Cc][Ss][Vv]')):
        add(parse_hdfc_credit_billing(f))

    # ICICI credit cards
    for subdir, src in [('amazon', 'icici_amazon'), ('coral', 'icici_coral')]:
        p = SOURCES['icici'] / subdir
        if p.exists():
            for f in sorted(p.glob('*.[Cc][Ss][Vv]')):
                add(parse_icici_credit(f, src))

    # ICICI savings
    for f in sorted(SOURCES['icici'].glob('*.[Cc][Ss][Vv]')):
        add(parse_icici_savings(f))

    # Scapia (PDF — skip unless pdfplumber available)
    try:
        import pdfplumber  # noqa: F401
        print("  ⚠  pdfplumber found but Scapia parser not yet implemented — skipping")
    except ImportError:
        print("  ℹ  pdfplumber not installed — skipping Scapia PDFs")

    return all_txns


def apply_labels(txns: list[Transaction]) -> list[Transaction]:
    return [t._replace(label=lbl)
            for t in txns
            if (lbl := label(t.narration, t.text, t.is_debit)) is not None]


def deduplicate(txns: list[Transaction]) -> list[Transaction]:
    seen: set[tuple] = set()
    out = []
    for t in txns:
        key = (t.text[:60], t.label, round(t.amount))
        if key not in seen:
            seen.add(key)
            out.append(t)
    return out


def balance(txns: list[Transaction]) -> list[Transaction]:
    by_cls: dict[str, list[Transaction]] = defaultdict(list)
    for t in txns:
        by_cls[t.label].append(t)
    out = []
    for cls, items in by_cls.items():
        if len(items) > MAX_PER_CLASS:
            step = len(items) / MAX_PER_CLASS
            items = [items[int(i * step)] for i in range(MAX_PER_CLASS)]
        out.extend(items)
    return out

# ─── Tokenizer (CoreML-compatible bag-of-words) ───────────────────────────────

def tokenize(text: str) -> dict[str, float]:
    tokens = re.findall(r'[a-z]{3,}', text.lower())
    bow: dict[str, float] = {}
    for tok in tokens:
        bow[tok] = bow.get(tok, 0) + 1.0
    for a, b in zip(tokens, tokens[1:]):
        bg = f"{a}_{b}"
        bow[bg] = bow.get(bg, 0) + 1.0
    return bow

# ─── Training ─────────────────────────────────────────────────────────────────

def train_model(texts: list[str], labels: list[str]):
    from sklearn.feature_extraction import DictVectorizer
    from sklearn.linear_model import LogisticRegression
    from sklearn.metrics import classification_report
    from sklearn.model_selection import train_test_split
    from sklearn.pipeline import Pipeline

    X = [tokenize(t) for t in texts]
    X_tr, X_va, y_tr, y_va = train_test_split(
        X, labels, test_size=0.2, random_state=42, stratify=labels
    )
    pipe = Pipeline([
        ('dv', DictVectorizer(sparse=False)),
        ('lr', LogisticRegression(max_iter=1000, C=1.0, class_weight='balanced',
                                   solver='lbfgs', multi_class='multinomial')),
    ])
    pipe.fit(X_tr, y_tr)
    preds = pipe.predict(X_va)
    acc   = float((np.array(preds) == np.array(y_va)).mean())
    report = classification_report(y_va, preds, zero_division=0)
    return pipe, acc, report

# ─── Exports ──────────────────────────────────────────────────────────────────

def export_createml_json(txns: list[Transaction], path: Path) -> None:
    samples = [{'text': t.text, 'label': t.label} for t in txns]
    path.write_text(json.dumps(samples, indent=2, ensure_ascii=False))
    print(f"  ✓ CreateML JSON  : {path}  ({len(samples)} examples)")


def export_coreml(pipe, path: Path) -> bool:
    try:
        import coremltools as ct
        model = ct.converters.sklearn.convert(
            pipe,
            input_features='token_counts',
            output_feature_names='category',
        )
        model.author = 'FinanceOS Training Pipeline'
        model.short_description = (
            'Transaction category classifier — DictVectorizer + LogisticRegression. '
            'Input: token_counts (dictionary<string,double>). '
            'Use MLModel directly, not NLModel.'
        )
        model.version = '2'
        model.save(str(path))
        print(f"  ✓ CoreML model   : {path}")
        return True
    except Exception as exc:
        print(f"  ✗ CoreML export failed: {exc}")
        print("    → Use CreateML with training-category.json instead (Option B below).")
        return False

# ─── Main ─────────────────────────────────────────────────────────────────────

def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    print("═══ FinanceOS Category Classifier Training Pipeline ═══\n")

    print("1. Parsing statements …")
    raw = load_all()
    print(f"   Raw transactions : {len(raw)}")

    print("\n2. Labeling …")
    labeled = apply_labels(raw)
    print(f"   Labeled          : {len(labeled)}  (unlabeled/skipped: {len(raw) - len(labeled)})")

    labeled = deduplicate(labeled)
    print(f"   After dedup      : {len(labeled)}")

    labeled = balance(labeled)
    counts  = Counter(t.label for t in labeled)
    labeled = [t for t in labeled if counts[t.label] >= MIN_PER_CLASS]
    counts  = Counter(t.label for t in labeled)
    print(f"   After balancing  : {len(labeled)}  across {len(counts)} classes")

    print("\n3. Class distribution:")
    total = len(labeled)
    for lbl, cnt in sorted(counts.items(), key=lambda x: -x[1]):
        bar = '█' * min(cnt // 3, 35)
        print(f"   {cnt:4d} ({cnt*100//total:2d}%)  {lbl:35s} {bar}")

    if len(counts) < 3:
        print("\n⚠  Too few classes — import more diverse statements and re-run.")
        sys.exit(1)

    print(f"\n4. Training ({len(labeled)} examples, {len(counts)} classes) …")
    texts  = [t.text for t in labeled]
    labels = [t.label for t in labeled]
    pipe, acc, report = train_model(texts, labels)
    print(f"   Validation accuracy: {acc:.1%}")
    print()
    print(report)

    # Save report
    rpt_path = OUT_DIR / 'evaluation-report.txt'
    rpt_path.write_text(
        f"Validation accuracy: {acc:.1%}\n\n"
        "Class distribution:\n" +
        '\n'.join(f"  {v:4d}  {k}" for k, v in sorted(counts.items(), key=lambda x: -x[1])) +
        f"\n\nClassification Report:\n{report}"
    )

    print("5. Exporting …")
    export_createml_json(labeled, OUT_DIR / 'training-category.json')
    coreml_path = OUT_DIR / 'TransactionCategoryClassifier.mlmodel'
    coreml_ok   = export_coreml(pipe, coreml_path)
    print(f"  ✓ Evaluation     : {rpt_path}")

    deploy_path = RESOURCES / 'TransactionCategoryClassifier.mlmodel'
    print(f"""
═══ Next Steps ═══

Option A — sklearn CoreML model (MLModel path, no NLModel):
  The exported .mlmodel accepts a token dictionary, not raw text.
  CoreMLCategorizer already supports this via its MLModel fallback path.
  Deploy:
    cp {coreml_path} \\
       {deploy_path}
  Then rebuild:  swift build --package-path Packages/FinanceIntelligence

Option B — CreateML Text Classifier (NLModel path, recommended):
  Gives NLModel-compatible output → zero Swift code changes needed.
    1.  open -a 'Create ML'
    2.  New Document → Text Classifier
    3.  Training Data → {OUT_DIR}/training-category.json
    4.  Columns: text input / label target
    5.  Train → Evaluate (target ≥ 80% validation accuracy)
    6.  Export → rename TransactionCategoryClassifier.mlmodel
    7.  cp ~/Downloads/TransactionCategoryClassifier.mlmodel \\
           {deploy_path}
""")


if __name__ == '__main__':
    main()
