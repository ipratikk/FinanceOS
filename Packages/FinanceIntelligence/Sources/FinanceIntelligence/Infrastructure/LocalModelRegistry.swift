import Foundation
import CoreML
import CommonCrypto

/// Local filesystem-based model registry. Loads model_registry.yaml from app bundle.
public final class LocalModelRegistry: ModelRegistry {
    private let bundle: Bundle
    private let entries: [String: ModelRegistryEntry]

    /// Initialize from model_registry.yaml in bundle.
    /// - Parameters:
    ///   - bundle: Bundle containing Resources/model_registry.yaml (default: main)
    ///   - registryPath: Resource path without extension (default: "model_registry")
    public init(bundle: Bundle = .main, registryPath: String = "model_registry") throws {
        guard let url = bundle.url(forResource: registryPath, withExtension: "yaml") else {
            throw ModelRegistryError.registryNotFound(registryPath)
        }

        let yaml = try String(contentsOf: url, encoding: .utf8)
        let modelsList = try Self.parseModelsYAML(yaml)
        let entriesDict = Dictionary(uniqueKeysWithValues: modelsList.map { entry in
            (entry.name, entry)
        })

        self.bundle = bundle
        self.entries = entriesDict
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

    public func version(for name: ModelName) -> ModelVersion? {
        guard let entry = entries[name.rawValue] else { return nil }
        return ModelVersion(
            name: entry.name,
            version: entry.version,
            datasetVersion: entry.datasetVersion,
            trainingDate: entry.trainingDate,
            artifactHash: entry.artifactSHA256
        )
    }

    public func validate(_ name: ModelName) throws {
        let entry = try entry(for: name)

        guard entry.status == .active || entry.status == .shadow else {
            throw ModelRegistryError.modelNotActive(name.rawValue, entry.status)
        }

        if entry.artifactType == .coreml {
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
        } else if entry.artifactType == .mlx {
            guard bundle.url(
                forResource: entry.artifactFilename,
                withExtension: nil,
                subdirectory: "MLX"
            ) != nil else {
                throw ModelRegistryError.artifactNotFound(entry.artifactFilename)
            }
        }
    }

    public func models(withStatus status: ModelStatus) -> [ModelRegistryEntry] {
        entries.values.filter { $0.status == status }
    }

    // MARK: - Private

    private func entry(for name: ModelName) throws -> ModelRegistryEntry {
        guard let entry = entries[name.rawValue] else {
            throw ModelRegistryError.modelNotFound(name.rawValue)
        }

        guard entry.status == .active || entry.status == .shadow else {
            throw ModelRegistryError.modelNotActive(name.rawValue, entry.status)
        }

        return entry
    }

    private func validateSHA256(url: URL, expected: String) throws {
        let actual = try sha256OfFile(url)

        guard actual == expected else {
            throw ModelRegistryError.hashMismatch("", expected: expected, actual: actual)
        }
    }

    private func sha256OfFile(_ url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - YAML Parsing (minimal)

    private static func parseModelsYAML(_ yaml: String) throws -> [ModelRegistryEntry] {
        var models: [ModelRegistryEntry] = []
        let lines = yaml.split(separator: "\n", omittingEmptySubsequences: true)
        var currentModel: [String: String] = [:]

        for line in lines {
            let trimmed = String(line).trimmingCharacters(in: .whitespaces)

            if trimmed.starts(with: "- name:") {
                if !currentModel.isEmpty {
                    if let entry = try? Self.parseModelEntry(currentModel) {
                        models.append(entry)
                    }
                }
                let value = trimmed.replacingOccurrences(of: "- name: ", with: "")
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                currentModel = ["name": value]
            } else if trimmed.starts(with: "models:") || trimmed.isEmpty {
                // Skip
            } else if let idx = trimmed.firstIndex(of: ":"), !currentModel.isEmpty {
                let key = String(trimmed[..<idx]).trimmingCharacters(in: .whitespaces)
                let value = String(trimmed[trimmed.index(idx, offsetBy: 1)...])
                    .trimmingCharacters(in: .whitespaces)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                currentModel[key] = value
            }
        }

        if !currentModel.isEmpty {
            if let entry = try? parseModelEntry(currentModel) {
                models.append(entry)
            }
        }

        return models
    }

    private static func parseModelEntry(_ dict: [String: String]) throws -> ModelRegistryEntry {
        let name = dict["name"] ?? ""
        let version = dict["version"] ?? "0.1.0"
        let displayName = dict["display_name"] ?? name
        let artifactFilename = dict["artifact_filename"] ?? ""
        let artifactTypeStr = dict["artifact_type"] ?? "coreml"
        let artifactType = ArtifactType(rawValue: artifactTypeStr) ?? .coreml
        let task = dict["task"] ?? ""
        let inputType = dict["input_type"] ?? "text"
        let outputClasses = Int(dict["output_classes"] ?? "0") ?? 0
        let datasetVersion = dict["dataset_version"] ?? ""
        let trainingDate = dict["training_date"] ?? ""
        let evaluationDate = dict["evaluation_date"] ?? ""
        let artifactSHA256 = dict["artifact_sha256"] ?? ""
        let coremlSHA256 = dict["coreml_sha256"] ?? ""
        let trainingCommit = dict["training_commit"] ?? ""
        let datasetCommit = dict["dataset_commit"] ?? ""
        let minOSVersion = dict["min_os_version"] ?? "17.0"
        let memoryMB = Int(dict["memory_mb"] ?? "0") ?? 0
        let statusStr = dict["status"] ?? "planned"
        let status = ModelStatus(rawValue: statusStr) ?? .planned

        return ModelRegistryEntry(
            name: name,
            version: version,
            displayName: displayName,
            artifactFilename: artifactFilename,
            artifactType: artifactType,
            task: task,
            inputType: inputType,
            outputClasses: outputClasses,
            datasetVersion: datasetVersion,
            trainingDate: trainingDate,
            evaluationDate: evaluationDate,
            metrics: [:],
            artifactSHA256: artifactSHA256,
            coremlSHA256: coremlSHA256,
            trainingCommit: trainingCommit,
            datasetCommit: datasetCommit,
            minOSVersion: minOSVersion,
            memoryMB: memoryMB,
            status: status
        )
    }
}

private let kCCSHA256DigestLength: Int32 = 32
