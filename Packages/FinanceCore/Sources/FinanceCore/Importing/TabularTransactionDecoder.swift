//
//  TabularTransactionDecoder.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation

enum TabularTransactionDecoder {
    static func decodeStatement(
        _ rows: [[String]]
    ) throws -> ParsedStatement {
        guard !rows.isEmpty else {
            return ParsedStatement(
                institution: "Unknown",
                accountName: "Unknown",
                transactions: []
            )
        }

        let (metadata, transactionRows) = try extractMetadata(rows)
        let transactions = try decodeTransactions(transactionRows)

        let (periodStart, periodEnd) = extractPeriod(from: transactions)
        var totalDebit: Int64 = 0
        var totalCredit: Int64 = 0

        for transaction in transactions {
            if transaction.amountMinorUnits < 0 {
                totalDebit -= transaction.amountMinorUnits
            } else {
                totalCredit += transaction.amountMinorUnits
            }
        }

        return ParsedStatement(
            institution: metadata.institution,
            accountName: metadata.accountName,
            cardLast4: metadata.cardLast4,
            statementPeriodStart: periodStart,
            statementPeriodEnd: periodEnd,
            currency: metadata.currency,
            totalDebit: totalDebit,
            totalCredit: totalCredit,
            transactions: transactions
        )
    }


    private static func index(
        in headers: [String],
        matchingAnyOf candidates: [String]
    ) -> Int? {
        headers.firstIndex { header in
            candidates.contains(header)
        }
    }

    private static func value(
        at index: Int,
        in row: [String]
    ) -> String {
        guard row.indices.contains(index) else {
            return ""
        }

        return row[index]
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func nonEmptyValue(
        _ value: String
    ) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func normalizeHeader(
        _ header: String
    ) -> String {
        header
            .lowercased()
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
    }

    private static func parseAmountMinorUnits(
        row: [String],
        amountIndex: Int?,
        debitIndex: Int?,
        creditIndex: Int?
    ) throws -> Int64 {
        if let amountIndex {
            return try parseAmountMinorUnits(
                value(at: amountIndex, in: row)
            )
        }

        let debitValue = debitIndex.map { value(at: $0, in: row) }
            .flatMap(nonEmptyValue(_:))
        let creditValue = creditIndex.map { value(at: $0, in: row) }
            .flatMap(nonEmptyValue(_:))

        if let debitValue {
            return try -abs(
                parseAmountMinorUnits(debitValue)
            )
        }

        if let creditValue {
            return try abs(
                parseAmountMinorUnits(creditValue)
            )
        }

        throw TransactionImportError.invalidAmount("")
    }

    private static func parseDate(
        _ value: String
    ) throws -> Date {
        let formatters = [
            "yyyy-MM-dd",
            "dd/MM/yyyy",
            "MM/dd/yyyy",
            "dd-MM-yyyy",
            "dd MMM yyyy",
            "dd MMM yy"
        ].map(makeDateFormatter)

        for formatter in formatters {
            if let date = formatter.date(from: value) {
                return date
            }
        }

        throw TransactionImportError.invalidDate(value)
    }

    private static func parseAmountMinorUnits(
        _ value: String
    ) throws -> Int64 {
        let sanitized = value
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "₹", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "INR", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let decimal = Decimal(string: sanitized) else {
            throw TransactionImportError.invalidAmount(value)
        }

        let minorUnitsDecimal = decimal * 100
        let rounded = NSDecimalNumber(decimal: minorUnitsDecimal).rounding(
            accordingToBehavior: nil
        )

        return rounded.int64Value
    }

    private static func makeDateFormatter(
        _ format: String
    ) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = format
        return formatter
    }

    private static func isoDateString(
        from date: Date
    ) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: date)
    }

    private struct StatementMetadata {
        let institution: String
        let accountName: String
        let cardLast4: String?
        let currency: String
    }

    private static func extractMetadata(
        _ rows: [[String]]
    ) throws -> (StatementMetadata, [[String]]) {
        let detectors: [StatementDetector] = [
            ICICIStatementDetector(),
            HDFCStatementDetector(),
            AmexStatementDetector()
        ]

        var detected: DetectedStatementMetadata?
        for detector in detectors {
            if let metadata = detector.detect(from: rows) {
                detected = metadata
                break
            }
        }

        let institution = detected?.institution ?? "Unknown"
        let accountName = detected?.accountName ?? "Unknown"
        let cardLast4 = detected?.cardLast4
        let transactionStartIndex = detected?.transactionStartIndex ?? 0

        let transactionRows = Array(rows.dropFirst(transactionStartIndex))
        let currency = transactionRows.first.map(extractCurrencyFromHeaders) ?? "INR"

        return (
            StatementMetadata(
                institution: institution,
                accountName: accountName,
                cardLast4: cardLast4,
                currency: currency
            ),
            transactionRows
        )
    }


    private static func decodeTransactions(
        _ rows: [[String]]
    ) throws -> [ParsedTransaction] {
        guard !rows.isEmpty else { return [] }

        let headerRow = rows[0]
        let normalizedHeaders = headerRow.map(normalizeHeader)
        let currency = extractCurrencyFromHeaders(headerRow)

        guard let dateIndex = index(
            in: normalizedHeaders,
            matchingAnyOf: ["date", "posteddate", "transactiondate", "txndate"]
        ) else {
            throw TransactionImportError.missingRequiredColumn("date")
        }

        guard let descriptionIndex = index(
            in: normalizedHeaders,
            matchingAnyOf: ["description", "details", "transactiondetails", "narration", "merchant"]
        ) else {
            throw TransactionImportError.missingRequiredColumn("description")
        }

        let amountIndex = index(
            in: normalizedHeaders,
            matchingAnyOf: ["amountinrs", "amount", "transactionamount"]
        )

        let debitIndex = index(
            in: normalizedHeaders,
            matchingAnyOf: ["debit", "withdrawal", "debitamount"]
        )

        let creditIndex = index(
            in: normalizedHeaders,
            matchingAnyOf: ["credit", "deposit", "creditamount"]
        )

        let billingSignIndex = index(
            in: normalizedHeaders,
            matchingAnyOf: ["billingamountsign"]
        )

        let rewardPointsIndex = index(
            in: normalizedHeaders,
            matchingAnyOf: ["rewardpointheader", "rewardpoints", "points"]
        )

        guard amountIndex != nil || debitIndex != nil || creditIndex != nil else {
            throw TransactionImportError.missingRequiredColumn("amount")
        }

        let minColumnCount = max(dateIndex, descriptionIndex, amountIndex ?? 0) + 1

        return try rows
            .dropFirst()
            .compactMap { row in
                if row.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                    return nil
                }

                if row.count < minColumnCount {
                    return nil
                }

                if isCardNumberRow(row) {
                    return nil
                }

                let dateString = value(at: dateIndex, in: row)
                let description = value(at: descriptionIndex, in: row)

                let postedAt = try parseDate(dateString)
                let amountMinorUnits: Int64

                if let amountIndex {
                    amountMinorUnits = try parseAmountWithSign(
                        row: row,
                        amountIndex: amountIndex,
                        billingSignIndex: billingSignIndex
                    )
                } else {
                    amountMinorUnits = try parseAmountMinorUnits(
                        row: row,
                        amountIndex: nil,
                        debitIndex: debitIndex,
                        creditIndex: creditIndex
                    )
                }

                let rewardPoints: Int? = rewardPointsIndex.flatMap { idx in
                    let pointsStr = value(at: idx, in: row)
                    return Int(pointsStr)
                }

                let fingerprint = [
                    isoDateString(from: postedAt),
                    description,
                    String(amountMinorUnits),
                    currency
                ].joined(separator: "|")

                return ParsedTransaction(
                    postedAt: postedAt,
                    description: description,
                    amountMinorUnits: amountMinorUnits,
                    currencyCode: currency,
                    sourceFingerprint: fingerprint,
                    rewardPoints: rewardPoints
                )
            }
    }

    private static func parseAmountWithSign(
        row: [String],
        amountIndex: Int,
        billingSignIndex: Int?
    ) throws -> Int64 {
        let amountStr = value(at: amountIndex, in: row)
        var amount = try parseAmountMinorUnits(amountStr)

        if let billingSignIndex {
            let sign = value(at: billingSignIndex, in: row).uppercased()
            if sign == "CR" {
                amount = abs(amount)
            } else {
                amount = -abs(amount)
            }
        }

        return amount
    }

    private static func extractPeriod(
        from transactions: [ParsedTransaction]
    ) -> (Date?, Date?) {
        guard !transactions.isEmpty else { return (nil, nil) }
        let dates = transactions.map(\.postedAt).sorted()
        return (dates.first, dates.last)
    }

    private static func extractCurrencyFromHeaders(
        _ headers: [String]
    ) -> String {
        for header in headers {
            let upper = header.uppercased()
            if upper.contains("USD") {
                return "USD"
            } else if upper.contains("EUR") {
                return "EUR"
            } else if upper.contains("GBP") {
                return "GBP"
            } else if upper.contains("INR") || upper.contains("RS") {
                return "INR"
            }
        }
        return "INR"
    }

    private static func isCardNumberRow(_ row: [String]) -> Bool {
        guard let firstCell = row.first else { return false }
        let trimmed = firstCell.trimmingCharacters(in: .whitespacesAndNewlines)

        let allDigitsAndX = trimmed.allSatisfy { char in
            char.isNumber || char == "X" || char == "x"
        }

        let hasMinCardLength = trimmed.count >= 12

        return allDigitsAndX && hasMinCardLength
    }
}
