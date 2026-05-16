@testable import FinanceCore
import GRDB
import Testing

@Test
func migrationAndSeedingCreateTransactions() throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(
        in: &migrator
    )

    let dbQueue = try DatabaseQueue()

    try migrator.migrate(dbQueue)

    try dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
        try DatabaseSeeder.seedAccounts(
            in: database
        )
        try DatabaseSeeder.seedCards(
            in: database
        )
        try DatabaseSeeder.seedTransactions(
            in: database
        )

        let transactions = try Transaction
            .fetchAll(database)

        #expect(transactions.count == 3)
        #expect(transactions.contains { transaction in
            transaction.accountID != nil && transaction.cardID == nil
        })
        #expect(transactions.contains { transaction in
            transaction.accountID == nil && transaction.cardID != nil
        })
    }
}

@Test
func transactionSeedingIsIdempotent() throws {
    var migrator = DatabaseMigrator()
    AppMigration.registerMigrations(
        in: &migrator
    )

    let dbQueue = try DatabaseQueue()

    try migrator.migrate(dbQueue)

    try dbQueue.write { database in
        try DatabaseSeeder.seedBanks(in: database)
        try DatabaseSeeder.seedAccounts(
            in: database
        )
        try DatabaseSeeder.seedCards(
            in: database
        )
        try DatabaseSeeder.seedTransactions(
            in: database
        )
        try DatabaseSeeder.seedTransactions(
            in: database
        )

        let transactionsCount = try Transaction
            .fetchCount(database)

        #expect(transactionsCount == 3)
    }
}
