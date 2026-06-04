import CoreML
import Foundation
import Tokenizers
import ZIPFoundation

/// Generates 128-dim L2-normalized float vectors from transaction narrations
/// using NarrationEmbedder v0.1 (BERT + mean-pool + linear projection).
///
/// Model is downloaded on first use from GitHub Releases and cached in
/// Application Support. Tokenizer is bundled in the app (8.7 MB).
/// @unchecked Sendable: actor isolation guarantees thread safety.
public actor EmbeddingGenerator {
    public static let dimension: Int = 128
    static let sequenceLength: Int = 64

    static let modelReleasePath = "https://github.com/ipratikk/FinanceOS/releases/download/" +
        "models-v0.1/NarrationEmbedder_v0.1.mlmodelc.zip"

    static var modelCacheDir: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("FinanceOS/Models", isDirectory: true)
    }

    static var compiledModelURL: URL {
        modelCacheDir.appendingPathComponent("NarrationEmbedder_v0.1.mlmodelc", isDirectory: true)
    }

    private let model: MLModel
    private let tokenizer: any Tokenizer

    public init() async throws {
        let modelURL = try await Self.ensureModelDownloaded()
        model = try await MLModel.load(contentsOf: modelURL)
        tokenizer = try await Self.loadBundledTokenizer()
    }

    /// Generate an L2-normalized Float32[128] embedding for the given text.
    /// Throws if the model is unavailable or inference fails.
    public func embed(_ text: String) throws -> [Float] {
        guard !text.isEmpty else { throw EmbeddingError.emptyInput }

        // encode() returns token IDs; build attention mask (1=real, 0=pad)
        let rawIds = tokenizer.encode(text: text)
        let (inputIds, attentionMask) = Self.padOrTruncate(
            ids: rawIds,
            realCount: rawIds.count
        )

        let inputIdsArray = try MLMultiArray(shape: [1, Self.sequenceLength as NSNumber], dataType: .int32)
        let attentionMaskArray = try MLMultiArray(shape: [1, Self.sequenceLength as NSNumber], dataType: .int32)

        for i in 0 ..< Self.sequenceLength {
            inputIdsArray[[0, i] as [NSNumber]] = NSNumber(value: inputIds[i])
            attentionMaskArray[[0, i] as [NSNumber]] = NSNumber(value: attentionMask[i])
        }

        let input = try MLDictionaryFeatureProvider(dictionary: [
            "input_ids": MLFeatureValue(multiArray: inputIdsArray),
            "attention_mask": MLFeatureValue(multiArray: attentionMaskArray)
        ])
        let output = try model.prediction(from: input)

        guard let embedding = output.featureValue(for: "embedding")?.multiArrayValue else {
            throw EmbeddingError.missingOutput
        }
        return (0 ..< Self.dimension).map { Float(truncating: embedding[$0]) }
    }

    // MARK: - Private

    private static func padOrTruncate(ids: [Int], realCount: Int) -> ([Int], [Int]) {
        var ids = Array(ids.prefix(sequenceLength))
        let realLen = min(realCount, sequenceLength)
        let mask = (0 ..< sequenceLength).map { $0 < realLen ? 1 : 0 }
        while ids.count < sequenceLength {
            ids.append(0)
        }
        return (ids, mask)
    }

    private static func loadBundledTokenizer() async throws -> any Tokenizer {
        guard let folder = Bundle.module.resourceURL else {
            throw EmbeddingError.tokenizerNotFound
        }
        // swift-transformers calls fatalError (not throw) when BPETokenizer is selected
        // but merges are absent. Validate upfront so try? in callers can catch this safely.
        try validateBPECompatibility(in: folder)
        return try await AutoTokenizer.from(modelFolder: folder)
    }

    private static func validateBPECompatibility(in folder: URL) throws {
        let url = folder.appendingPathComponent("tokenizer.json")
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let model = json["model"] as? [String: Any],
              (model["type"] as? String) == "BPE",
              model["merges"] != nil else {
            throw EmbeddingError.incompatibleTokenizer
        }
    }

    private static func ensureModelDownloaded() async throws -> URL {
        if FileManager.default.fileExists(atPath: compiledModelURL.path) {
            return compiledModelURL
        }
        try FileManager.default.createDirectory(at: modelCacheDir, withIntermediateDirectories: true)
        guard let downloadURL = URL(string: modelReleasePath) else {
            throw EmbeddingError.modelNotFoundAfterUnzip
        }
        let (zipURL, _) = try await URLSession.shared.download(from: downloadURL)
        try unzipModel(from: zipURL, to: modelCacheDir)
        guard FileManager.default.fileExists(atPath: compiledModelURL.path) else {
            throw EmbeddingError.modelNotFoundAfterUnzip
        }
        return compiledModelURL
    }

    private static func unzipModel(from zipURL: URL, to destination: URL) throws {
        let archive = try Archive(url: zipURL, accessMode: .read)
        for entry in archive {
            let entryDest = destination.appendingPathComponent(entry.path)
            _ = try archive.extract(entry, to: entryDest)
        }
    }
}

public enum EmbeddingError: Error, LocalizedError {
    case emptyInput
    case tokenizerNotFound
    case incompatibleTokenizer
    case missingOutput
    case modelNotFoundAfterUnzip

    public var errorDescription: String? {
        switch self {
        case .emptyInput: "Cannot embed empty text"
        case .tokenizerNotFound: "Bundled tokenizer files not found in app resources"
        case .incompatibleTokenizer: "Bundled tokenizer is not BPE or is missing merges — replace tokenizer files"
        case .missingOutput: "CoreML model did not produce 'embedding' output"
        case .modelNotFoundAfterUnzip: "Model directory not found after unzip"
        }
    }
}
