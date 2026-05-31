import FinanceCore
import FinanceIntelligence
import FinanceUI
import Observation
import SwiftUI

@Observable
@MainActor
final class TransactionDetailViewModel {
    private let row: TransactionRow

    var categoryId: String?
    var isUserCorrected: Bool

    // MARK: Intelligence

    var recurringPattern: RecurringPattern?
    var person: Person?
    var relationship: Relationship?

    init(row: TransactionRow) {
        self.row = row
        categoryId = row.categoryId
        isUserCorrected = row.isUserCorrected
    }

    // MARK: - Category

    var categoryDisplayName: String {
        guard let id = categoryId else { return "Uncategorized" }
        return CategoryTaxonomy.current.category(forId: id)?.displayName ?? id.capitalized
    }

    var categoryColor: Color {
        CategorySymbol.color(for: categoryId)
    }

    var categorySymbol: String {
        CategorySymbol.symbol(for: categoryId)
    }

    var showNarration: Bool {
        row.title != row.displayTitle
    }

    var postedDateText: String {
        FormatterCache.fullDayDate.string(from: row.postedAt)
    }

    var postedTimeText: String {
        FormatterCache.dayAndTime.string(from: row.postedAt)
    }

    // MARK: - Intelligence computed

    var nextExpectedDate: Date? {
        guard let pattern = recurringPattern else { return nil }
        let cal = Calendar.current
        let now = Date()
        switch pattern.cadence {
        case .monthly:
            if let day = pattern.dayOfMonthHint {
                var comps = cal.dateComponents([.year, .month], from: now)
                comps.day = day
                if let candidate = cal.date(from: comps), candidate > now { return candidate }
                comps.month = (comps.month ?? 1) + 1
                return cal.date(from: comps)
            }
            return cal.date(byAdding: .day, value: 30, to: pattern.lastSeenAt)
        case .weekly:
            return cal.date(byAdding: .day, value: 7, to: pattern.lastSeenAt)
        case .biWeekly:
            return cal.date(byAdding: .day, value: 14, to: pattern.lastSeenAt)
        case .quarterly:
            return cal.date(byAdding: .month, value: 3, to: pattern.lastSeenAt)
        case .yearly:
            return cal.date(byAdding: .year, value: 1, to: pattern.lastSeenAt)
        case .irregular:
            return nil
        }
    }

    var relationshipIcon: String {
        switch relationship?.type {
        case .landlord: return "house.fill"
        case .tenant: return "house"
        case .family: return "person.2.fill"
        case .employer: return "briefcase.fill"
        case .employee: return "briefcase"
        case .reimbursement: return "arrow.2.squarepath"
        case .loanProvider, .loanRecipient: return "banknote"
        default: return "person.fill"
        }
    }

    // MARK: - Load

    func applyCorrection(transactionId: UUID, newCategoryId: String) {
        categoryId = newCategoryId
        isUserCorrected = true
    }

    func loadIntelligence() async {
        let merchantKey = row.merchantName?.lowercased() ?? ""
        let container = IntelligenceContainer.shared

        // 1. Look up recurring pattern by merchant key
        if !merchantKey.isEmpty {
            recurringPattern = try? await container.recurringPatternRepository.fetch(merchantKey: merchantKey)
        }

        // 2. Resolve person: from pattern's personId, or by name/alias match in persons table
        let allPersons = await (try? container.personRepository.fetchAll()) ?? []

        if let pid = recurringPattern?.personId, let uuid = UUID(uuidString: pid) {
            person = allPersons.first { $0.id == uuid }
        }

        if person == nil, !merchantKey.isEmpty {
            person = allPersons.first { person in
                person.canonicalName.lowercased() == merchantKey ||
                    person.aliases.contains { $0.lowercased() == row.title.lowercased() }
            }
        }

        // 3. If person found, load their relationship + person-keyed recurring pattern
        if let person {
            let pid = person.id.uuidString
            relationship = try? await container.relationshipRepository.fetch(toPersonId: pid)
            if recurringPattern == nil {
                recurringPattern = try? await container.recurringPatternRepository.fetch(personId: pid)
            }
        }
    }
}
