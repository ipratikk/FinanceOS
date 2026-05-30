import Foundation

/// In-memory store for `Person` entities, deduplicated by normalized name and UPI handle.
///
/// Thread-safe via Swift actor isolation. Session-scoped in Phase 2 — not persisted across restarts.
/// Phase 3 will back this with a GRDB repository.
public actor PersonEntityStore {
    private var persons: [UUID: Person] = [:]
    private var nameIndex: [String: UUID] = [:] // normalized name → person ID
    private var upiIndex: [String: UUID] = [:] // lowercase UPI handle → person ID

    public init() {}

    /// Returns the existing `Person` matching `name` or `upiHandle`, or creates a new one.
    /// Updates `transactionCount`, `lastSeenAt`, and `aliases` on each call.
    public func findOrCreate(name: String, upiHandle: String?, date: Date) -> Person {
        let normalized = normalize(name)
        let upiKey = upiHandle?.lowercased()

        if let existing = findExisting(normalized: normalized, upiKey: upiKey) {
            return update(existing, rawName: name, upiHandle: upiHandle, date: date)
        }
        return create(canonicalName: titleCase(name), rawName: name, upiHandle: upiHandle, date: date)
    }

    /// Returns a snapshot of all known persons.
    public func fetchAll() -> [Person] {
        Array(persons.values)
    }

    /// Returns the person with the given ID, or nil if unknown.
    public func person(forId id: UUID) -> Person? {
        persons[id]
    }

    /// Total number of known persons.
    public var count: Int {
        persons.count
    }
}

// MARK: - Private Helpers

private extension PersonEntityStore {
    func findExisting(normalized: String, upiKey: String?) -> Person? {
        if let id = nameIndex[normalized] { return persons[id] }
        if let key = upiKey, let id = upiIndex[key] { return persons[id] }
        return nil
    }

    @discardableResult
    func update(_ person: Person, rawName: String, upiHandle: String?, date: Date) -> Person {
        var updated = person
        updated.transactionCount += 1
        updated.lastSeenAt = date
        if !updated.aliases.contains(rawName) {
            updated.aliases.append(rawName)
        }
        if updated.upiHandle == nil, let handle = upiHandle {
            updated.upiHandle = handle
            upiIndex[handle.lowercased()] = updated.id
        }
        persons[updated.id] = updated
        return updated
    }

    func create(canonicalName: String, rawName: String, upiHandle: String?, date: Date) -> Person {
        let person = Person(
            canonicalName: canonicalName,
            aliases: [rawName],
            upiHandle: upiHandle,
            transactionCount: 1,
            firstSeenAt: date,
            lastSeenAt: date
        )
        persons[person.id] = person
        nameIndex[normalize(canonicalName)] = person.id
        if let handle = upiHandle {
            upiIndex[handle.lowercased()] = person.id
        }
        return person
    }

    func normalize(_ name: String) -> String {
        var result = name.uppercased()
        let titles = ["MR ", "MRS ", "MS ", "DR ", "PROF ", "SHRI ", "SMT ", "KUM "]
        for title in titles where result.hasPrefix(title) {
            result = String(result.dropFirst(title.count))
        }
        return result
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    func titleCase(_ input: String) -> String {
        input
            .components(separatedBy: " ")
            .map { $0.isEmpty ? $0 : $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
}
