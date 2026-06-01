import Foundation

/// Labeled narration dataset for person/merchant classification training.
public struct LabeledNarration: Codable, Identifiable, Sendable {
    public let id: UUID
    public let narration: String
    public let vpa: String?
    public let amountMinorUnits: Int64
    public let direction: TransactionDirection
    public let label: NarrationLabel
    public let bank: String
    public let source: DataSource
    public let createdAt: Date
    public let annotatedBy: String?

    public enum TransactionDirection: String, Codable, Sendable {
        case debit, credit
    }

    public enum NarrationLabel: String, Codable, Sendable {
        case person
        case merchant
        case unknown
    }

    public enum DataSource: String, Codable, Sendable {
        case userCorrection = "user_correction"
        case parserFixture = "parser_fixture"
        case synthetic
        case manual = "manual_annotation"
    }

    public init(
        narration: String,
        vpa: String?,
        amountMinorUnits: Int64,
        direction: TransactionDirection,
        label: NarrationLabel,
        bank: String,
        source: DataSource,
        annotatedBy: String? = nil
    ) {
        id = UUID()
        self.narration = narration
        self.vpa = vpa
        self.amountMinorUnits = amountMinorUnits
        self.direction = direction
        self.label = label
        self.bank = bank
        self.source = source
        self.annotatedBy = annotatedBy
        createdAt = Date()
    }
}

/// Collection of labeled narrations with metadata.
public struct LabeledNarrationCollection: Codable, Sendable {
    public let version: String
    public let createdAt: Date
    public let datasetHash: String
    public let examples: [LabeledNarration]
    public let metadata: CollectionMetadata

    public struct CollectionMetadata: Codable, Sendable {
        public let totalCount: Int
        public let personCount: Int
        public let merchantCount: Int
        public let unknownCount: Int
        public let bankCoverage: [String: Int]
        public let sourceCoverage: [String: Int]
        public let annotationGuidelines: String

        public var balance: [String: Double] {
            let total = Double(totalCount)
            return [
                "person": Double(personCount) / total,
                "merchant": Double(merchantCount) / total,
                "unknown": Double(unknownCount) / total
            ]
        }
    }

    public init(examples: [LabeledNarration], annotationGuidelines: String = "") {
        version = "1.0"
        createdAt = Date()
        self.examples = examples

        let personCount = examples.count(where: { $0.label == .person })
        let merchantCount = examples.count(where: { $0.label == .merchant })
        let unknownCount = examples.count(where: { $0.label == .unknown })

        var bankCov: [String: Int] = [:]
        var sourceCov: [String: Int] = [:]
        for example in examples {
            bankCov[example.bank, default: 0] += 1
            sourceCov[example.source.rawValue, default: 0] += 1
        }

        metadata = CollectionMetadata(
            totalCount: examples.count,
            personCount: personCount,
            merchantCount: merchantCount,
            unknownCount: unknownCount,
            bankCoverage: bankCov,
            sourceCoverage: sourceCov,
            annotationGuidelines: annotationGuidelines
        )

        datasetHash = Self.computeHash(examples)
    }

    private static func computeHash(_ examples: [LabeledNarration]) -> String {
        let sorted = examples.sorted { $0.narration < $1.narration }
        var hasher = SHA256()
        for example in sorted {
            hasher.update(data: example.narration.data(using: .utf8) ?? Data())
            hasher.update(data: example.label.rawValue.data(using: .utf8) ?? Data())
        }
        return hasher.finalize().hexEncodedString
    }
}

struct SHA256 {
    private var content: String = ""

    mutating func update(data: Data) {
        content.append(String(data: data, encoding: .utf8) ?? "")
    }

    func finalize() -> Data {
        let hash = content.hashValue.magnitude
        return String(format: "%032x", hash).data(using: .utf8) ?? Data()
    }
}

extension Data {
    var hexEncodedString: String {
        map { String(format: "%02hhx", $0) }.joined()
    }
}
