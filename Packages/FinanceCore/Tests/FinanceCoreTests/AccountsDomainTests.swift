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
        try DatabaseSeeder.seedInstitutions(
            in: database
        )

        try DatabaseSeeder.seedAccounts(
            in: database
        )

        try DatabaseSeeder.seedCards(
            in: database
        )

        let institutions = try Institution
            .fetchAll(database)
        let accounts = try Account
            .fetchAll(database)
        let cards = try Card
            .fetchAll(database)

        let institutionsByID = Dictionary(
            uniqueKeysWithValues: institutions.map { institution in
                (institution.id, institution)
            }
        )
        let accountsByID = Dictionary(
            uniqueKeysWithValues: accounts.map { account in
                (account.id, account)
            }
        )

        #expect(institutions.count == 4)
        #expect(accounts.count == 2)
        #expect(cards.count == 5)
        #expect(accounts.allSatisfy { account in
            institutions.contains { institution in
                institution.id == account.institutionID
            }
        })
        #expect(cards.allSatisfy { card in
            institutions.contains { institution in
                institution.id == card.institutionID
            }
        })

        let hdfcAccount = accounts.first { account in
            account.name == "HDFC Bank Account"
        }
        let iciciAccount = accounts.first { account in
            account.name == "ICICI Bank Account"
        }
        let hdfcRegalia = cards.first { card in
            card.name == "HDFC Regalia"
        }
        let iciciCoral = cards.first { card in
            card.name == "ICICI Coral"
        }
        let iciciAmazonPay = cards.first { card in
            card.name == "ICICI Amazon Pay"
        }
        let amexPlatinumTravel = cards.first { card in
            card.name == "American Express Platinum Travel"
        }
        let scapia = cards.first { card in
            card.name == "Scapia"
        }

        #expect(hdfcRegalia?.accountID == hdfcAccount?.id)
        #expect(iciciCoral?.accountID == iciciAccount?.id)
        #expect(iciciAmazonPay?.accountID == iciciAccount?.id)
        #expect(amexPlatinumTravel?.accountID == nil)
        #expect(scapia?.accountID == nil)

        #expect(hdfcRegalia.flatMap { card in
            card.accountID.flatMap { accountsByID[$0] }?.name
        } == "HDFC Bank Account")
        #expect(iciciCoral.flatMap { card in
            card.accountID.flatMap { accountsByID[$0] }?.name
        } == "ICICI Bank Account")
        #expect(amexPlatinumTravel.flatMap { card in
            institutionsByID[card.institutionID]?.name
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
        try DatabaseSeeder.seedInstitutions(
            in: database
        )
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
