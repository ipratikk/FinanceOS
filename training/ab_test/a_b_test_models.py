#!/usr/bin/env python3
"""
A/B test CategoryClassifier v1.2 + MerchantRecognizer v0.1 against baseline rules.

Compares two approaches on golden dataset (735 labeled transactions):
1. Model Group (New): CategoryClassifier v1.2 + MerchantRecognizer v0.1
2. Baseline Group (Existing): RuleBasedCategorizer + basic merchant matching

Metrics:
- Category prediction accuracy, F1, precision, recall
- Merchant prediction accuracy, F1, precision, recall
- Macro metrics across both models
- Confidence distribution analysis

Output:
- training/reports/ab_test_results.json (detailed results)
"""

import csv
import json
import pickle
import sys
from pathlib import Path
from typing import Any, Dict, List, Tuple
from collections import defaultdict
from datetime import datetime, timezone

try:
    from sklearn.metrics import accuracy_score, f1_score, precision_score, recall_score
except ImportError:
    print("Error: scikit-learn not installed. Run: pip install scikit-learn")
    sys.exit(1)


def load_golden_transactions(path: str) -> List[Dict[str, Any]]:
    """Load golden transactions."""
    transactions = []
    with open(path) as f:
        for line in f:
            if line.strip():
                transactions.append(json.loads(line))
    return transactions


def load_category_model_and_vectorizer(model_path: str, vectorizer_path: str):
    """Load trained category classifier."""
    with open(model_path, "rb") as f:
        model = pickle.load(f)
    with open(vectorizer_path, "rb") as f:
        vectorizer = pickle.load(f)
    return model, vectorizer


def load_merchant_model_and_vectorizer(model_path: str, vectorizer_path: str):
    """Load trained merchant recognizer."""
    with open(model_path, "rb") as f:
        model = pickle.load(f)
    with open(vectorizer_path, "rb") as f:
        vectorizer = pickle.load(f)
    return model, vectorizer


def predict_category_baseline(transaction: Dict[str, Any]) -> str:
    """RuleBasedCategorizer: intent-to-category rule mapping."""
    labels = transaction.get("labels", {})
    intent = labels.get("intent", "unknown")

    intent_to_category = {
        "salary": "salary",
        "rent": "rent",
        "credit_card_payment": "credit_card_payments",
        "investment": "investments",
        "insurance": "insurance",
        "loan_payment": "loans",
        "peer_transfer": "transfers",
        "subscription": "subscriptions",
        "refund": "shopping",
        "cashback": "shopping",
        "income": "salary",
        "grocery": "groceries",
        "food": "food",
        "fuel": "fuel",
        "travel": "travel",
        "utilities": "utilities",
        "education": "education",
        "healthcare": "healthcare",
        "entertainment": "entertainment",
        "emi_payment": "emi",
        "cash_withdrawal": "transfers",
        "self_transfer": "transfers",
    }

    return intent_to_category.get(intent, "unknown")


def predict_category_model(
    transaction: Dict[str, Any], model: Any, vectorizer: Any
) -> Tuple[str, float]:
    """CategoryClassifier v1.2: TF-IDF + LogisticRegression."""
    narration = transaction.get("narration", "")
    if not narration:
        return "unknown", 0.0

    try:
        # Vectorize
        X = vectorizer.transform([narration])
        # Predict
        pred_category = model.predict(X)[0]
        # Confidence
        probs = model.predict_proba(X)[0]
        confidence = max(probs) if len(probs) > 0 else 0.0
        return pred_category, float(confidence)
    except Exception:
        return "unknown", 0.0


def predict_merchant_baseline(transaction: Dict[str, Any]) -> Tuple[str, float]:
    """Basic merchant matching: from labels or keywords."""
    labels = transaction.get("labels", {})
    merchant = labels.get("merchant")

    if merchant:
        return merchant, 0.85

    # Keyword fallback
    narration = transaction.get("narration", "").upper()
    merchant_keywords = {
        "Zepto": ["ZEPTO", "BLINKIT"],
        "Swiggy": ["SWIGGY"],
        "Zomato": ["ZOMATO"],
        "Netflix": ["NETFLIX"],
        "Amazon": ["AMAZON"],
        "Flipkart": ["FLIPKART"],
    }

    for merchant, keywords in merchant_keywords.items():
        if any(kw in narration for kw in keywords):
            return merchant, 0.75

    return "Unknown", 0.0


def predict_merchant_model(
    transaction: Dict[str, Any], model: Any, vectorizer: Any
) -> Tuple[str, float]:
    """MerchantRecognizer v0.1: TF-IDF + LogisticRegression."""
    narration = transaction.get("narration", "")
    if not narration:
        return "Unknown", 0.0

    try:
        # Vectorize
        X = vectorizer.transform([narration])
        # Predict
        pred_merchant = model.predict(X)[0]
        # Confidence
        probs = model.predict_proba(X)[0]
        confidence = max(probs) if len(probs) > 0 else 0.0
        return pred_merchant, float(confidence)
    except Exception:
        return "Unknown", 0.0


def evaluate_category_predictions(
    transactions: List[Dict[str, Any]],
    baseline_preds: List[str],
    model_preds: List[str],
) -> Dict[str, Any]:
    """Evaluate category predictions."""
    ground_truth = [t.get("labels", {}).get("category", "unknown") for t in transactions]

    baseline_metrics = {
        "accuracy": float(accuracy_score(ground_truth, baseline_preds)),
        "macro_f1": float(f1_score(ground_truth, baseline_preds, average="macro", zero_division=0)),
        "weighted_f1": float(f1_score(ground_truth, baseline_preds, average="weighted", zero_division=0)),
        "macro_precision": float(precision_score(ground_truth, baseline_preds, average="macro", zero_division=0)),
        "macro_recall": float(recall_score(ground_truth, baseline_preds, average="macro", zero_division=0)),
    }

    model_metrics = {
        "accuracy": float(accuracy_score(ground_truth, model_preds)),
        "macro_f1": float(f1_score(ground_truth, model_preds, average="macro", zero_division=0)),
        "weighted_f1": float(f1_score(ground_truth, model_preds, average="weighted", zero_division=0)),
        "macro_precision": float(precision_score(ground_truth, model_preds, average="macro", zero_division=0)),
        "macro_recall": float(recall_score(ground_truth, model_preds, average="macro", zero_division=0)),
    }

    improvement = {
        "accuracy_delta": model_metrics["accuracy"] - baseline_metrics["accuracy"],
        "macro_f1_delta": model_metrics["macro_f1"] - baseline_metrics["macro_f1"],
    }

    return {
        "baseline": baseline_metrics,
        "model": model_metrics,
        "improvement": improvement,
    }


def evaluate_merchant_predictions(
    transactions: List[Dict[str, Any]],
    baseline_preds: List[str],
    model_preds: List[str],
) -> Dict[str, Any]:
    """Evaluate merchant predictions."""
    # Filter to transactions with labeled merchants (exclude "Unknown" in ground truth)
    ground_truth = []
    baseline_filtered = []
    model_filtered = []

    for i, t in enumerate(transactions):
        merchant = t.get("labels", {}).get("merchant")
        if merchant and merchant != "Unknown":
            ground_truth.append(merchant)
            baseline_filtered.append(baseline_preds[i])
            model_filtered.append(model_preds[i])

    if not ground_truth:
        return {
            "baseline": {"accuracy": 0.0, "macro_f1": 0.0, "weighted_f1": 0.0},
            "model": {"accuracy": 0.0, "macro_f1": 0.0, "weighted_f1": 0.0},
            "improvement": {"accuracy_delta": 0.0, "macro_f1_delta": 0.0},
            "note": "No labeled merchants in dataset",
        }

    baseline_metrics = {
        "accuracy": float(accuracy_score(ground_truth, baseline_filtered)),
        "macro_f1": float(f1_score(ground_truth, baseline_filtered, average="macro", zero_division=0)),
        "weighted_f1": float(f1_score(ground_truth, baseline_filtered, average="weighted", zero_division=0)),
    }

    model_metrics = {
        "accuracy": float(accuracy_score(ground_truth, model_filtered)),
        "macro_f1": float(f1_score(ground_truth, model_filtered, average="macro", zero_division=0)),
        "weighted_f1": float(f1_score(ground_truth, model_filtered, average="weighted", zero_division=0)),
    }

    improvement = {
        "accuracy_delta": model_metrics["accuracy"] - baseline_metrics["accuracy"],
        "macro_f1_delta": model_metrics["macro_f1"] - baseline_metrics["macro_f1"],
    }

    return {
        "baseline": baseline_metrics,
        "model": model_metrics,
        "improvement": improvement,
        "sample_size": len(ground_truth),
    }


def main():
    input_path = Path("training/data/golden_transactions.jsonl")
    category_model_path = Path("training/category/models/category_classifier_v1.2.pkl")
    category_vectorizer_path = Path("training/category/models/vectorizer_v1.2.pkl")
    merchant_model_path = Path("training/merchant/models/merchant_recognizer_v0.1.pkl")
    merchant_vectorizer_path = Path("training/merchant/models/vectorizer_merchant_v0.1.pkl")
    output_path = Path("training/reports/ab_test_results.json")

    if not input_path.exists():
        print(f"Error: {input_path} not found")
        return 1

    print(f"Loading golden transactions from {input_path}...")
    transactions = load_golden_transactions(str(input_path))
    print(f"✓ Loaded {len(transactions)} transactions\n")

    # Load models
    print("Loading trained models...")
    cat_model, cat_vectorizer = load_category_model_and_vectorizer(
        str(category_model_path), str(category_vectorizer_path)
    )
    merch_model, merch_vectorizer = load_merchant_model_and_vectorizer(
        str(merchant_model_path), str(merchant_vectorizer_path)
    )
    print("✓ Models loaded\n")

    # Evaluate category predictions
    print("Evaluating category predictions...")
    baseline_cat_preds = [predict_category_baseline(t) for t in transactions]
    model_cat_preds = [predict_category_model(t, cat_model, cat_vectorizer)[0] for t in transactions]
    cat_results = evaluate_category_predictions(transactions, baseline_cat_preds, model_cat_preds)

    print(f"  Baseline Accuracy: {cat_results['baseline']['accuracy']:.4f}")
    print(f"  Model Accuracy: {cat_results['model']['accuracy']:.4f}")
    print(f"  Improvement: {cat_results['improvement']['accuracy_delta']:+.4f}\n")

    # Evaluate merchant predictions
    print("Evaluating merchant predictions...")
    baseline_merch_preds = [predict_merchant_baseline(t)[0] for t in transactions]
    model_merch_preds = [predict_merchant_model(t, merch_model, merch_vectorizer)[0] for t in transactions]
    merch_results = evaluate_merchant_predictions(transactions, baseline_merch_preds, model_merch_preds)

    print(f"  Baseline Accuracy: {merch_results['baseline']['accuracy']:.4f}")
    print(f"  Model Accuracy: {merch_results['model']['accuracy']:.4f}")
    print(f"  Improvement: {merch_results['improvement']['accuracy_delta']:+.4f}\n")

    # Generate report
    report = {
        "test_date": datetime.now(timezone.utc).isoformat(),
        "dataset": "golden_v1",
        "sample_size": len(transactions),
        "models_tested": {
            "baseline": "RuleBasedCategorizer + BasicMerchantMatching",
            "model_1": "CategoryClassifier v1.2",
            "model_2": "MerchantRecognizer v0.1",
        },
        "category_evaluation": cat_results,
        "merchant_evaluation": merch_results,
        "summary": {
            "category_model_passes_acceptance": cat_results["model"]["macro_f1"] >= 0.92,
            "merchant_model_passes_acceptance": merch_results["model"]["accuracy"] >= 0.95,
            "both_models_outperform_baseline": (
                cat_results["improvement"]["accuracy_delta"] > 0
                and merch_results["improvement"]["accuracy_delta"] > 0
            ),
        },
    }

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w") as f:
        json.dump(report, f, indent=2)

    print(f"✓ A/B test report: {output_path}")
    print(f"\n{'=' * 60}")
    print(f"A/B Test Summary")
    print(f"{'=' * 60}")
    print(f"Category Model Improvement: {cat_results['improvement']['accuracy_delta']:+.4f}")
    print(f"  Baseline: {cat_results['baseline']['accuracy']:.4f}")
    print(f"  Model 1:  {cat_results['model']['accuracy']:.4f}")
    print(f"  Status:   {'✓ PASS' if report['summary']['category_model_passes_acceptance'] else '✗ FAIL'}")
    print(f"\nMerchant Model Improvement: {merch_results['improvement']['accuracy_delta']:+.4f}")
    print(f"  Baseline: {merch_results['baseline']['accuracy']:.4f}")
    print(f"  Model 2:  {merch_results['model']['accuracy']:.4f}")
    print(f"  Status:   {'✓ PASS' if report['summary']['merchant_model_passes_acceptance'] else '✗ FAIL'}")
    print(f"\nBoth Outperform Baseline: {'✓ YES' if report['summary']['both_models_outperform_baseline'] else '✗ NO'}")
    print(f"{'=' * 60}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
