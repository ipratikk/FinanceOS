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
| User corrections (FeedbackStore) | TBD | ✓ Collection module | Query GRDBFeedbackStore |
| Synthetic generation | ~30 | ✓ Implemented | Template-based |
| Manual annotation | TBD | Pending | Spreadsheet + validation |

### Components Added (Phase 2)

1. **FeedbackStoreDataCollector** (`MachineLearning/FeedbackStoreDataCollector.swift`)
   - Collects labeled examples from FeedbackStore events
   - Maps merchant corrections → person/merchant labels
   - Maps category corrections → inferred labels
   - Confidence scoring for each example

2. **DatasetOrchestrator** (`MachineLearning/DatasetOrchestrator.swift`)
   - Coordinates collection from all sources
   - Methods: `seedFromFixtures()`, `collectFromFeedbackStore()`, `generateSynthetic()`
   - Exports to JSON/CSV
   - Generates ~30 synthetic narrations for gaps
   - Actor-based for thread safety

### Immediate Next Steps

1. **Integrate FeedbackStore in AppContainer** 
   - [ ] Pass FeedbackStore instance to DatasetOrchestrator
   - [ ] Document usage pattern for data collection

2. **Validate Collected Data**
   - [ ] Run on dev instance with sample FeedbackStore data
   - [ ] Measure balance (person/merchant/unknown %)
   - [ ] Identify gaps in bank coverage

3. **Manual Review & Deduplication**
   - [ ] Export current dataset (fixtures + synthetic)
   - [ ] Review ~50 examples for quality
   - [ ] Remove duplicates
   - [ ] Document review process

4. **Reach 500+ Examples Milestone**
   - [ ] Combine all sources
   - [ ] Document each source contribution
   - [ ] Publish seed dataset

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
