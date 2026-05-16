@testable import FinanceCore
import GRDB
import Testing

@Test
func migrationAndSeedingCreateLinkedAccountsAndCards() throws {
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

        let banks = try Bank
            .fetchAll(database)
        let accounts = try Account
            .fetchAll(database)
        let cards = try Card
            .fetchAll(database)

        let banksByID = Dictionary(
            uniqueKeysWithValues: banks.map { bank in
                (bank.id, bank)
            }
        )
        let accountsByID = Dictionary(
            uniqueKeysWithValues: accounts.map { account in
                (account.id, account)
            }
        )

        #expect(banks.count == 4)
        #expect(accounts.count == 2)
        #expect(cards.count == 5)
        #expect(accounts.allSatisfy { account in
            banks.contains { bank in
                bank.id == account.bankId
            }
        })
        #expect(cards.allSatisfy { card in
            banks.contains { bank in
                bank.id == card.bankId
            }
        })

        let hdfcAccount = accounts.first { account in
            account.accountName == "HDFC Bank Account"
        }
        let iciciAccount = accounts.first { account in
            account.accountName == "ICICI Bank Account"
        }
        let hdfcRegalia = cards.first { card in
            card.cardName == "HDFC Regalia"
        }
        let iciciCoral = cards.first { card in
            card.cardName == "ICICI Coral"
        }
        let iciciAmazonPay = cards.first { card in
            card.cardName == "ICICI Amazon Pay"
        }
        let amexPlatinumTravel = cards.first { card in
            card.cardName == "American Express Platinum Travel"
        }
        let scapia = cards.first { card in
            card.cardName == "Scapia"
        }

        #expect(hdfcRegalia?.linkedAccountId == hdfcAccount?.id)
        #expect(iciciCoral?.linkedAccountId == iciciAccount?.id)
        #expect(iciciAmazonPay?.linkedAccountId == iciciAccount?.id)
        #expect(amexPlatinumTravel?.linkedAccountId == nil)
        #expect(scapia?.linkedAccountId == nil)

        #expect(hdfcRegalia.flatMap { card in
            card.linkedAccountId.flatMap { accountsByID[$0] }?.accountName
        } == "HDFC Bank Account")
        #expect(iciciCoral.flatMap { card in
            card.linkedAccountId.flatMap { accountsByID[$0] }?.accountName
        } == "ICICI Bank Account")
        #expect(amexPlatinumTravel.flatMap { card in
            banksByID[card.bankId]?.name
        } == "Amex")
    }
}

@Test
func accountAndCardSeedingIsIdempotent() throws {
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
        try DatabaseSeeder.seedAccounts(
            in: database
        )
        try DatabaseSeeder.seedCards(
            in: database
        )
        try DatabaseSeeder.seedCards(
            in: database
        )

        let accountsCount = try Account
            .fetchCount(database)
        let cardsCount = try Card
            .fetchCount(database)

        #expect(accountsCount == 2)
        #expect(cardsCount == 5)
    }
}
