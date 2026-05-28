# CoreML Integration: Three Approaches

Python sklearn→CoreML is broken (coremltools 9.0+ dropped sklearn support).  
Here are three viable alternatives.

---

## Approach 2: CreateML (Recommended for Fast MVProduction)

**Tool**: Apple's native Xcode Create ML app (no code needed).

### Workflow
1. Prepare CSV: `text, label` columns
2. Open Xcode → Create ML → Text Classifier
3. Import training CSV
4. Train (Xcode UI handles it)
5. Export .mlmodel
6. Copy to `Packages/FinanceIntelligence/Sources/FinanceIntelligence/Resources/`

### Pros
- ✅ Apple-native, fully supported
- ✅ Simple UI (no code)
- ✅ Fast training on Mac
- ✅ Produces .mlmodel directly (not .mlpackage)

### Cons
- ❌ GUI-based (not scriptable)
- ❌ Manual export step

### Status
- **Training data**: `/tmp/createml_training.csv` ready
- **Integration**: Update CoreMLCategorizer to load `.mlmodel` (not `.mlpackage`)

---

## Approach 3: PyTorch → CoreML (Flexible, Modern)

**Tool**: PyTorch + coremltools (full support for PyTorch→CoreML).

### Workflow
```bash
pip install -r requirements-pytorch.txt
python train_pytorch.py --data fixtures/sample_transactions.csv --output models/
```

### Features
- Text embedding → dense layer → classification
- Fully differentiable
- Easy to extend (add attention, etc.)
- coremltools has **full** PyTorch support (unlike sklearn)

### Pros
- ✅ scriptable (CI/CD friendly)
- ✅ Modern DL framework
- ✅ Extensible architecture

### Cons
- ❌ Larger model size
- ❌ Requires torch (30MB+ dependency)
- ❌ Training slower than sklearn

### Status
- **Script**: `tools/transaction-intelligence/train_pytorch.py` created
- **Requirements**: `requirements-pytorch.txt` added

---

## Approach 4: Swift Native (No Python)

**Tool**: Swift + LocalTransactionLearner pattern (already in codebase).

### Workflow
```bash
make intelligence-build
swift run FinanceIntelligenceCLI train fixtures/sample_transactions.csv --output models/
```

### Features
- Pure Swift k-NN learner (matches existing architecture)
- No external ML framework
- Integrates seamlessly with TransactionIntelligenceServiceImpl
- Training happens at app startup from user corrections (no offline model)

### Pros
- ✅ No external dependencies
- ✅ Matches existing on-device learning
- ✅ Lightweight
- ✅ Runs on device

### Cons
- ❌ No fixed .mlmodel artifact
- ❌ Learning is runtime-based (not pre-trained)

### Status
- **CLI Command**: `TrainingCommand.swift` created
- **Integration**: Add to FinanceIntelligenceCLI targets

---

## Recommendation

| Goal | Use |
|------|-----|
| **Quick MVP** | Approach 2 (CreateML) |
| **Production ML** | Approach 3 (PyTorch) |
| **No external deps** | Approach 4 (Swift native) |
| **Hybrid** | Approach 2 + Approach 4 (CreateML + user corrections) |

---

## Implementation Checklist

### If choosing Approach 2 (CreateML):
- [ ] Train in Xcode Create ML UI using `/tmp/createml_training.csv`
- [ ] Export .mlmodel to `Packages/FinanceIntelligence/Sources/FinanceIntelligence/Resources/`
- [ ] Update CoreMLCategorizer to load `.mlmodel` instead of `.mlpackage`
- [ ] Update Package.swift resources to include .mlmodel
- [ ] Test in app

### If choosing Approach 3 (PyTorch):
- [ ] Install PyTorch: `pip install -r requirements-pytorch.txt`
- [ ] Run: `python train_pytorch.py --data fixtures/sample_transactions.csv`
- [ ] Copy resulting .mlmodel to Resources/
- [ ] Same CoreMLCategorizer updates as Approach 2
- [ ] Add PyTorch+coremltools to build system (if CI/CD automation needed)

### If choosing Approach 4 (Swift):
- [ ] Integrate TrainingCommand into FinanceIntelligenceCLI main
- [ ] Update Makefile: `make intelligence-train` → Swift CLI
- [ ] Test: `make intelligence-build && make intelligence-train`
- [ ] No .mlmodel needed—uses LocalTransactionLearner at runtime

---

## Next Steps

1. Pick approach (recommend **2** for speed)
2. Execute implementation checklist
3. Test end-to-end (training → model → app inference)
4. Commit changes
