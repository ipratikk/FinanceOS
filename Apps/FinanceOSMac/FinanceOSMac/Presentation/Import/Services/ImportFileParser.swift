@preconcurrency import Apollo
import FinanceCore
import FinanceOSAPI
import Foundation
import OSLog

protocol StatementParsingProtocol: Sendable {
    func parse(fileURL: URL, password: String?) async throws -> ParsedStatement
}

/// Detects bank/last4/transaction-count for a statement by previewing it against
/// financeos-backend, which owns statement parsing end to end. Falls back to
/// filename-based last4 extraction for banks the backend can't yet extract from
/// statement content.
struct ImportFileParser: StatementParsingProtocol {
    private let logger = FinanceLogger.importPipeline
    private let graphQLClient: ApolloGraphQLClient

    init(graphQLClient: ApolloGraphQLClient) {
        self.graphQLClient = graphQLClient
    }

    func parse(fileURL: URL, password: String? = nil) async throws -> ParsedStatement {
        let fileName = fileURL.lastPathComponent
        let fileData = try Data(contentsOf: fileURL)
        let file = GraphQLFile(
            fieldName: "file",
            originalName: fileName,
            mimeType: "text/csv",
            data: fileData
        )
        let sealedPassword = try password.map { try ImportPasswordCrypto.seal($0) }
        let mutation = PreviewStatementMutation(
            file: "",
            password: sealedPassword.map {
                .some(EncryptedPassword(ephemeralPublicKey: $0.ephemeralPublicKey, ciphertext: $0.ciphertext))
            } ?? .null
        )
        let response = try await graphQLClient.upload(mutation: mutation, files: [file])
        let preview = response.previewStatement

        if preview.passwordRequired {
            throw FinanceCore.TransactionImportError.passwordProtected(fileName)
        }

        let filenameMetadata = FilenameMetadataExtractor().extractMetadata(from: fileName)
        let last4 = preview.last4 ?? filenameMetadata.accountLast4
        let isCard = preview.bankCode.contains("card")
        let bankName = Self.bankName(fromBankCode: preview.bankCode)

        logger.logInfo(
            "Previewed {file}: {count} txns from {bank}",
            ["file": fileName, "count": preview.transactionCount, "bank": bankName]
        )

        return ParsedStatement(
            bankName: bankName,
            accountName: bankName,
            accountLast4: isCard ? nil : last4,
            cardLast4: isCard ? last4 : nil,
            transactions: []
        )
    }

    private static func bankName(fromBankCode bankCode: String) -> String {
        let prefix = bankCode.split(separator: "_").first.map(String.init) ?? bankCode
        switch prefix.lowercased() {
        case "hdfc": return "HDFC"
        case "icici": return "ICICI"
        case "amex": return "American Express"
        case "axis": return "Axis"
        case "sbi": return "SBI"
        case "scapia": return "Scapia"
        default: return prefix.uppercased()
        }
    }
}
