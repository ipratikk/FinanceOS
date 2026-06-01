# ML-001: Build Person/Merchant Labeled Dataset — Progress

**Status**: Phase 1 Complete (Infrastructure). Phase 2 In Progress (Collection).

**Goal**: Build ≥5,000 labeled narrations for person/merchant classification training.

---

## Phase 1: Infrastructure ✓

### Components Built

1. **LabeledNarrationDataset** (`MachineLearning/LabeledNarrationDataset.swift`)
   - Core data model: `LabeledNarration` (narration, VPA, label, bank, source, etc.)
   - Collection wrapper: `LabeledNarrationCollection` with metadata
   - Supports hashing & versioning for dataset integrity

2. **DatasetCollector** (`MachineLearning/DatasetCollector.swift`)
   - Actor-based collector (thread-safe)
   - Methods: `addFromFixture()`, `addFromUserCorrection()`, `addSynthetic()`
   - Exports: JSON, CSV
   - Statistics: balance tracking, bank coverage

3. **FixtureNarrationExtractor** (`MachineLearning/FixtureNarrationExtractor.swift`)
   - Parses CSV/TXT test fixtures
   - Heuristic label inference
   - Basic person/merchant detection

4. **Annotation Guidelines** (`MachineLearning/ANNOTATION_GUIDELINES.md`)
   - Clear person/merchant/unknown definitions
   - Examples & edge cases
   - Labeling workflow
   - Target balance: ~35% person, ~50% merchant, ~15% unknown

5. **Test Dataset** (`FinanceTesting/TestDatasets/PersonMerchantDataset.swift`)
   - Seed examples from parser fixtures
   - Verified labels
   - Ready for annotation

6. **Tests** (`FinanceIntelligenceTests/DatasetCollectorTests.swift`)
   - 8 passing tests covering:
     - Collection from fixtures
     - CSV/JSON export
     - Statistics aggregation
     - Fixture extraction

---

## Phase 2: Data Collection (In Progress)

### Sources & Collection Strategy

| Source | Count | Status | Method |
|--------|-------|--------|--------|
| Parser fixtures (HDFC, ICICI) | ~20 | ✓ Extracted | CSV export |
| User corrections (FeedbackStore) | 0/TBD | Pending | Query GRDBFeedbackStore |
| Synthetic generation | 0/TBD | Pending | Template-based |
| Manual annotation | TBD | Pending | Spreadsheet + validation |

### Immediate Next Steps

1. **Extract from All Parsers** (target: +100 examples)
   - [ ] Fix `Scripts/collect_dataset.swift` for all fixture formats
   - [ ] Extract from SBI, Axis test fixtures (if available)
   - [ ] Verify no PII leaks

2. **Wire FeedbackStore Collection** (target: +500 examples)
   - [ ] Query `GRDBFeedbackStore` for `merchant_corrected` events
   - [ ] Infer label from correction context
   - [ ] Add `source: .userCorrection` to collected examples

3. **Synthetic Generation** (target: +200-500 examples)
   - [ ] Generate underrepresented narration patterns
   - [ ] Phone number VPA variants
   - [ ] Business name variants
   - [ ] Ambiguous/borderline cases

4. **Manual Annotation Workflow**
   - [ ] Set up spreadsheet template (CSV format)
   - [ ] Create validation checklist
   - [ ] Review & deduplicate before merging

---

## Current Stats

- **Examples collected**: ~20 from fixtures
- **Coverage**: HDFC, ICICI
- **Balance**: TBD (need full collection)
- **Next milestone**: 500 examples (foundation)

---

## Acceptance Criteria (ML-001)

- [ ] ≥5,000 labeled examples
- [ ] Multi-bank coverage (HDFC, ICICI, Axis, SBI, at least one more)
- [ ] Balanced: documented ratio
- [ ] Annotation guidelines written ✓
- [ ] Dataset versioned with hash ✓
- [ ] PII policy enforced (no raw names stored) ✓
- [ ] Source documented for each example ✓

---

## Technical Debt & Notes

- `Scripts/collect_dataset.swift` needs refinement for fixture column detection
- Heuristic label inference needs improvement for edge cases
- Dataset hash using simple Swift hash (consider SHA-256 upgrade)

---

## Dependencies

- Completes: None (phase 1 standalone)
- Enables: ML-002 (PersonMerchantClassifier training)

---

Last updated: 2026-06-01
