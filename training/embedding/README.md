# Narration Embedding Model v0.1

Sentence transformer trained on Indian financial narrations using triplet contrastive learning.

## Requirements

- Same-merchant cosine similarity >= 0.85
- Diff-merchant cosine similarity <= 0.30
- ANN Top-1 recall >= 0.90
- Float32[128] output

## Structure

```
training/embedding/
├── train.py              # Triplet loss training
├── evaluate.py           # Metrics: cosine similarity, ANN recall
├── benchmark.py          # Performance benchmarks
├── export_coreml.py      # CoreML export pipeline
├── generate_triplets.py  # Triplet dataset generation
└── README.md
```

## Training Data

Triplet examples:
- Anchor: narration from merchant M
- Positive: different narration from same merchant M
- Negative: narration from different merchant

Generated from synthetic Indian financial transaction corpus.

## Model

Sentence transformer with:
- Text encoder (DistilBERT or equivalent)
- Triplet margin loss
- Output: Float32[128] embeddings

## Artifacts

- `NarrationEmbedder_v0.1.mlpackage`: CoreML model
- `embedding_index.faiss`: FAISS ANN index for Top-1 recall testing
- `model_registry_entry.yaml`: Metadata

## Metrics

```
Same-merchant cosine similarity:  >= 0.85
Diff-merchant cosine similarity:  <= 0.30
ANN Top-1 Recall:                 >= 0.90
Model size:                        < 50MB (CoreML)
Inference latency (CPU):           < 100ms per embedding
```

## Usage

```bash
python training/embedding/generate_triplets.py
python training/embedding/train.py
python training/embedding/evaluate.py
python training/embedding/benchmark.py
python training/embedding/export_coreml.py
```
