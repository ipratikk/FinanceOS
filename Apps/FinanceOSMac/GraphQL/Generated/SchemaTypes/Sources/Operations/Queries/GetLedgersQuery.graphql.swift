// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public nonisolated struct GetLedgersQuery: GraphQLQuery {
    public static let operationName: String = "GetLedgers"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
        definition: .init(
            #"query GetLedgers { ledgers { __typename id displayName kind last4 bank { __typename id name code } balance { __typename value currencyCode } lastStatementAt } }"#
        )
    )

    public init() {}

    public nonisolated struct Data: FinanceOSAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe)
        public init(_dataDict: DataDict) {
            __data = _dataDict
        }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType {
            FinanceOSAPI.Objects.Query
        }

        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] {
            [
                .field("ledgers", [Ledger].self)
            ]
        }

        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
            [
                GetLedgersQuery.Data.self
            ]
        }

        public var ledgers: [Ledger] {
            __data["ledgers"]
        }

        /// Ledger
        ///
        /// Parent Type: `Ledger`
        public nonisolated struct Ledger: FinanceOSAPI.SelectionSet {
            @_spi(Unsafe) public let __data: DataDict
            @_spi(Unsafe)
            public init(_dataDict: DataDict) {
                __data = _dataDict
            }

            @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType {
                FinanceOSAPI.Objects.Ledger
            }

            @_spi(Execution) public static var __selections: [ApolloAPI.Selection] {
                [
                    .field("__typename", String.self),
                    .field("id", FinanceOSAPI.ID.self),
                    .field("displayName", String.self),
                    .field("kind", GraphQLEnum<FinanceOSAPI.LedgerKind>.self),
                    .field("last4", String?.self),
                    .field("bank", Bank.self),
                    .field("balance", Balance.self),
                    .field("lastStatementAt", String?.self)
                ]
            }

            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                [
                    GetLedgersQuery.Data.Ledger.self
                ]
            }

            public var id: FinanceOSAPI.ID {
                __data["id"]
            }

            public var displayName: String {
                __data["displayName"]
            }

            public var kind: GraphQLEnum<FinanceOSAPI.LedgerKind> {
                __data["kind"]
            }

            public var last4: String? {
                __data["last4"]
            }

            public var bank: Bank {
                __data["bank"]
            }

            public var balance: Balance {
                __data["balance"]
            }

            /// ISO timestamp of the most recent successful statement upload, or null if none.
            public var lastStatementAt: String? {
                __data["lastStatementAt"]
            }

            /// Ledger.Bank
            ///
            /// Parent Type: `Bank`
            public nonisolated struct Bank: FinanceOSAPI.SelectionSet {
                @_spi(Unsafe) public let __data: DataDict
                @_spi(Unsafe)
                public init(_dataDict: DataDict) {
                    __data = _dataDict
                }

                @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType {
                    FinanceOSAPI.Objects.Bank
                }

                @_spi(Execution) public static var __selections: [ApolloAPI.Selection] {
                    [
                        .field("__typename", String.self),
                        .field("id", FinanceOSAPI.ID.self),
                        .field("name", String.self),
                        .field("code", String.self)
                    ]
                }

                @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                    [
                        GetLedgersQuery.Data.Ledger.Bank.self
                    ]
                }

                public var id: FinanceOSAPI.ID {
                    __data["id"]
                }

                public var name: String {
                    __data["name"]
                }

                public var code: String {
                    __data["code"]
                }
            }

            /// Ledger.Balance
            ///
            /// Parent Type: `Money`
            public nonisolated struct Balance: FinanceOSAPI.SelectionSet {
                @_spi(Unsafe) public let __data: DataDict
                @_spi(Unsafe)
                public init(_dataDict: DataDict) {
                    __data = _dataDict
                }

                @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType {
                    FinanceOSAPI.Objects.Money
                }

                @_spi(Execution) public static var __selections: [ApolloAPI.Selection] {
                    [
                        .field("__typename", String.self),
                        .field("value", Int.self),
                        .field("currencyCode", GraphQLEnum<FinanceOSAPI.CurrencyCode>.self)
                    ]
                }

                @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                    [
                        GetLedgersQuery.Data.Ledger.Balance.self
                    ]
                }

                public var value: Int {
                    __data["value"]
                }

                public var currencyCode: GraphQLEnum<FinanceOSAPI.CurrencyCode> {
                    __data["currencyCode"]
                }
            }
        }
    }
}
