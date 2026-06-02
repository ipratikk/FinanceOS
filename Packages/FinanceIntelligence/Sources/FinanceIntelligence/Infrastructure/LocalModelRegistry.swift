import Foundation
import CoreML

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
        let dict = try parseYAML(yaml)

        guard let modelsList = dict["models"] as? [[String: Any]] else {
            throw ModelRegistryError.invalidYAML("models array not found")
        }

        self.bundle = bundle
        self.entries = Dictionary(uniqueKeysWithValues: try modelsList.map { dict in
            let entry = try parseModelEntry(dict)
            return (entry.name, entry)
        })
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
        let actual: String

        if url.hasDirectoryPath {
            // .mlpackage is a directory: hash all files inside (sorted)
            actual = try sha256OfDirectory(url)
        } else {
            // Single file
            let data = try Data(contentsOf: url)
            actual = data.sha256Hex
        }

        guard actual == expected else {
            throw ModelRegistryError.hashMismatch("", expected: expected, actual: actual)
        }
    }

    private func sha256OfDirectory(_ path: URL) throws -> String {
        let fileManager = FileManager.default
        let files = try fileManager
            .contentsOfDirectory(at: path, includingPropertiesForKeys: nil)
            .sorted { $0.path < $1.path }

        var hasher = SHA256Hasher()

        for file in files {
            let data = try Data(contentsOf: file)
            hasher.update(data)
        }

        return hasher.finalize().hexString
    }

    // MARK: - YAML Parsing (minimal)

    private func parseYAML(_ yaml: String) throws -> [String: Any] {
        // Simple YAML parser for our registry format
        // In production, use Yams package
        var dict: [String: Any] = [:]
        var models: [[String: Any]] = []

        let lines = yaml.split(separator: "\n", omittingEmptySubsequences: true)
        var currentModel: [String: Any]?

        for line in lines {
            let trimmed = String(line).trimmingCharacters(in: .whitespaces)

            if trimmed.starts(with: "- name:") {
                if let model = currentModel {
                    models.append(model)
                }
                let name = trimmed.replacingOccurrences(of: "- name: ", with: "").trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                currentModel = ["name": name]
            } else if trimmed.starts(with: "models:") {
                // Do nothing, start collecting models
            } else if let model = currentModel, trimmed.contains(":") {
                let parts = trimmed.split(separator: ":", maxSplits: 1)
                if parts.count == 2 {
                    let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
                    let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
                        .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))

                    if key == "status", let status = ModelStatus(rawValue: value) {
                        model["status"] = status
                    } else if let intValue = Int(value) {
                        model[key] = intValue
                    } else {
                        model[key] = value
                    }
                }
            }
        }

        if let model = currentModel {
            models.append(model)
        }

        dict["models"] = models
        return dict
    }

    private func parseModelEntry(_ dict: [String: Any]) throws -> ModelRegistryEntry {
        let name = dict["name"] as? String ?? ""
        let version = dict["version"] as? String ?? "0.1.0"
        let displayName = dict["display_name"] as? String ?? name
        let artifactFilename = dict["artifact_filename"] as? String ?? ""
        let artifactTypeStr = dict["artifact_type"] as? String ?? "coreml"
        let artifactType = ArtifactType(rawValue: artifactTypeStr) ?? .coreml
        let task = dict["task"] as? String ?? ""
        let inputType = dict["input_type"] as? String ?? "text"
        let outputClasses = dict["output_classes"] as? Int ?? 0
        let datasetVersion = dict["dataset_version"] as? String ?? ""
        let trainingDate = dict["training_date"] as? String ?? ""
        let evaluationDate = dict["evaluation_date"] as? String ?? ""
        let metrics = dict["metrics"] as? [String: Double] ?? [:]
        let artifactSHA256 = dict["artifact_sha256"] as? String ?? ""
        let coremlSHA256 = dict["coreml_sha256"] as? String ?? ""
        let trainingCommit = dict["training_commit"] as? String ?? ""
        let datasetCommit = dict["dataset_commit"] as? String ?? ""
        let minOSVersion = dict["min_os_version"] as? String ?? "17.0"
        let memoryMB = dict["memory_mb"] as? Int ?? 0
        let statusStr = dict["status"] as? String ?? "planned"
        let status = dict["status"] as? ModelStatus ?? ModelStatus(rawValue: statusStr) ?? .planned

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
            metrics: metrics,
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

// MARK: - Hashing

struct SHA256Hasher {
    private var data = Data()

    mutating func update(_ data: Data) {
        self.data.append(data)
    }

    func finalize() -> SHA256Digest {
        // Use CommonCrypto via Foundation
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(data.count), &digest)
        }
        return SHA256Digest(digest)
    }
}

struct SHA256Digest {
    let bytes: [UInt8]

    init(_ bytes: [UInt8]) {
        self.bytes = bytes
    }

    var hexString: String {
        bytes.map { String(format: "%02x", $0) }.joined()
    }
}

extension Data {
    var sha256Hex: String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(self.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// CommonCrypto bridge
import CommonCrypto

private let CC_SHA256_DIGEST_LENGTH: Int32 = 32

@_silgen_name("CC_SHA256")
private func CC_SHA256(
    _ data: UnsafeRawPointer?,
    _ len: CC_LONG,
    _ md: UnsafeMutablePointer<UInt8>?
) -> UnsafeMutablePointer<UInt8>?
