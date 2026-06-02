---
doc: 007-model-registry
version: 0.1.0
status: Draft
date: 2026-06-02
---

# Model Registry — FinanceIntelligence Platform

## Purpose

Define the `ModelRegistry` system: the YAML schema for `model_registry.yaml`, the Swift `ModelRegistry` protocol and `LocalModelRegistry` implementation, model versioning strategy, artifact hash validation, and model promotion workflow. No model artifact path may be hardcoded in Swift; all model loading must go through the registry.

---

## Problem Statement

Current state: `CoreMLCategorizer` hardcodes `let modelName = "TransactionCategoryClassifier"`. This has several failure modes:

- Cannot pin a specific model version without recompiling
- No validation that the artifact matches the expected training run
- No rollback path if a new model regresses
- A/B testing requires code changes

The registry solves this by being the single source of truth for model → artifact resolution.

---

## model_registry.yaml Schema

Located at: `Sources/FinanceIntelligence/Resources/model_registry.yaml`

```yaml
schema_version: "1.0"
updated_at: "2026-06-02"

models:
  - name: category_classifier
    version: "1.2.0"
    display_name: "Transaction Category Classifier"
    artifact_filename: "TransactionCategoryClassifier_v1.2.mlpackage"
    artifact_type: coreml          # coreml | mlx | onnx
    task: text_classification
    input_type: text
    output_classes: 28
    dataset_version: "2026-05-15"
    training_date: "2026-05-20"
    evaluation_date: "2026-05-22"
    metrics:
      macro_f1: 0.937
      weighted_f1: 0.951
      accuracy: 0.949
    artifact_sha256: "a3f1c8d2e4b67890abcdef1234567890abcdef1234567890abcdef1234567890"
    coreml_sha256: "b4e2d9c3f5a78901bcdef2345678901bcdef2345678901bcdef2345678901"
    training_commit: "d34e5bf"
    dataset_commit: "8eff8fd"
    min_os_version: "17.0"
    memory_mb: 18
    status: active                 # active | shadow | deprecated | rollback

  - name: merchant_recognizer
    version: "0.1.0"
    display_name: "Merchant Recognition Model"
    artifact_filename: "MerchantRecognizer_v0.1.mlpackage"
    artifact_type: coreml
    task: text_classification
    input_type: text
    output_classes: 0              # 0 = open-set (unknown class supported)
    dataset_version: ""
    training_date: ""
    evaluation_date: ""
    metrics: {}
    artifact_sha256: ""
    coreml_sha256: ""
    training_commit: ""
    dataset_commit: ""
    min_os_version: "17.0"
    memory_mb: 0
    status: planned

  - name: intent_classifier
    version: "0.1.0"
    status: planned
    artifact_filename: "IntentClassifier_v0.1.mlpackage"
    artifact_type: coreml
    memory_mb: 0

  - name: income_classifier
    version: "0.1.0"
    status: planned
    artifact_filename: "IncomeClassifier_v0.1.mlpackage"
    artifact_type: coreml
    memory_mb: 0

  - name: embedding_encoder
    version: "0.1.0"
    status: planned
    artifact_filename: "NarrationEmbedder_v0.1.mlpackage"
    artifact_type: coreml
    memory_mb: 0

  - name: recurring_detector
    version: "0.1.0"
    status: planned
    artifact_filename: "RecurringDetector_v0.1.mlpackage"
    artifact_type: coreml
    memory_mb: 0

  - name: anomaly_detector
    version: "0.1.0"
    status: planned
    artifact_filename: "AnomalyDetector_v0.1.mlpackage"
    artifact_type: coreml
    memory_mb: 0

  - name: link_predictor
    version: "0.1.0"
    status: planned
    artifact_filename: "link_predictor_v0.1"
    artifact_type: mlx
    memory_mb: 0

  - name: description_generator
    version: "0.1.0"
    status: planned
    artifact_filename: "description_llm_v0.1"
    artifact_type: mlx
    memory_mb: 0
```

---

## Swift Protocol

```swift
// Protocols/ModelRegistry.swift

public protocol ModelRegistry: Sendable {
    /// Load a CoreML model artifact by logical name.
    func loadCoreML(_ name: ModelName) throws -> MLModel

    /// Load MLX model weights directory by logical name.
    func mlxArtifactPath(for name: ModelName) throws -> URL

    /// Returns the registered version metadata for a model.
    func version(for name: ModelName) -> ModelVersion?

    /// Validates artifact hash against registry entry.
    func validate(_ name: ModelName) throws

    /// Returns all models with the given status.
    func models(withStatus status: ModelStatus) -> [ModelRegistryEntry]
}

public enum ModelStatus: String, Codable {
    case active
    case shadow     // deployed for evaluation, not user-facing
    case deprecated
    case rollback   // previous active version, kept for revert
    case planned
}
```

---

## LocalModelRegistry Implementation

```swift
// Infrastructure/LocalModelRegistry.swift

public final class LocalModelRegistry: ModelRegistry {
    private let bundle: Bundle
    private let entries: [String: ModelRegistryEntry]

    public init(bundle: Bundle = .main, registryPath: String = "model_registry") throws {
        guard let url = bundle.url(forResource: registryPath, withExtension: "yaml") else {
            throw ModelRegistryError.registryNotFound(registryPath)
        }
        let yaml = try String(contentsOf: url)
        let parsed = try YAMLDecoder().decode(ModelRegistryFile.self, from: yaml)
        self.bundle = bundle
        self.entries = Dictionary(uniqueKeysWithValues: parsed.models.map { ($0.name, $0) })
    }

    public func loadCoreML(_ name: ModelName) throws -> MLModel {
        let entry = try entry(for: name)
        guard entry.artifactType == .coreml else {
            throw ModelRegistryError.wrongArtifactType(name.rawValue)
        }
        guard let url = bundle.url(
            forResource: entry.artifactFilename,
            withExtension: nil,
            subdirectory: "ML"
        ) else {
            throw ModelRegistryError.artifactNotFound(entry.artifactFilename)
        }
        if !entry.artifactSHA256.isEmpty {
            try validateSHA256(url: url, expected: entry.artifactSHA256)
        }
        return try MLModel(contentsOf: url)
    }

    public func mlxArtifactPath(for name: ModelName) throws -> URL {
        let entry = try entry(for: name)
        guard entry.artifactType == .mlx else {
            throw ModelRegistryError.wrongArtifactType(name.rawValue)
        }
        guard let url = bundle.url(
            forResource: entry.artifactFilename,
            withExtension: nil,
            subdirectory: "MLX"
        ) else {
            throw ModelRegistryError.artifactNotFound(entry.artifactFilename)
        }
        return url
    }

    private func entry(for name: ModelName) throws -> ModelRegistryEntry {
        guard let entry = entries[name.rawValue] else {
            throw ModelRegistryError.modelNotFound(name.rawValue)
        }
        guard entry.status == .active || entry.status == .shadow else {
            throw ModelRegistryError.modelNotActive(name.rawValue, entry.status)
        }
        return entry
    }
}

public enum ModelRegistryError: Error {
    case registryNotFound(String)
    case modelNotFound(String)
    case modelNotActive(String, ModelStatus)
    case artifactNotFound(String)
    case wrongArtifactType(String)
    case hashMismatch(String, expected: String, actual: String)
}
```

---

## SHA256 Validation

```python
# training/scripts/compute_artifact_hash.py
# Run this after export to get the hash for model_registry.yaml

import hashlib
import sys
from pathlib import Path

def sha256_of_directory(path: Path) -> str:
    """Hash all files in directory deterministically."""
    h = hashlib.sha256()
    for f in sorted(path.rglob("*")):
        if f.is_file():
            h.update(f.read_bytes())
    return h.hexdigest()

if __name__ == "__main__":
    p = Path(sys.argv[1])
    print(sha256_of_directory(p) if p.is_dir() else hashlib.sha256(p.read_bytes()).hexdigest())
```

---

## Model Versioning Strategy

Semantic versioning: `MAJOR.MINOR.PATCH`

| Change | Version bump |
|---|---|
| Retrained on new dataset (same label set) | MINOR |
| New output classes added | MAJOR |
| Bug fix in training script (no accuracy change) | PATCH |
| Architecture change | MAJOR |

---

## Promotion Workflow

```
[new model trained]
        │
        ▼
status: shadow
        │
        ├── Run shadow evaluation harness
        │   Compare new model vs. active on golden dataset
        │
        ├── IF new_macro_f1 >= current_macro_f1 - 0.005
        │       └── AND latency regression < 20%
        │               └── Approve for promotion
        │
        ▼
status: active  (previous active → status: rollback)
```

Promotion is a manual step requiring update to `model_registry.yaml` in a PR with benchmark results attached.

---

## Rollback Procedure

1. Change `status` of new model from `active` to `deprecated`
2. Change `status` of rollback model from `rollback` to `active`
3. Deploy registry update (app bundle update or OTA registry if hosted separately)

Registry changes do not require Swift recompilation.

---

## Model Loading in AppContainer

```swift
// AppContainer.swift
let registry = try LocalModelRegistry(bundle: .main)
let pipeline = IntelligencePipeline(container: IntelligenceContainer(registry: registry))
```

---

## Future: OTA Registry Updates

Phase 2+ consideration: host `model_registry.yaml` and model artifacts in a CDN. The `LocalModelRegistry` checks for a locally cached registry first, then falls back to the bundle-embedded registry. This enables:

- Model updates without App Store submission (within OS-permitted limits)
- A/B test rollouts to a fraction of users
- Emergency rollback without app release

Implementation deferred until post-Phase 3.

---

## Risks

| Risk | Mitigation |
|---|---|
| Registry YAML parse failure at launch | Catch error in AppContainer; fall through to emergency fallback (hardcoded model filename) |
| Artifact hash mismatch after App Store processing | Use directory-level hash for `.mlpackage` (which are directories); document known-good hash computation method |
| Shadow model accidentally served to users | `status: shadow` explicitly rejected in `loadCoreML`; must be promoted to `active` |
| Registry file not included in app bundle | Add `model_registry.yaml` to `.process("Resources/")` in Package.swift |
