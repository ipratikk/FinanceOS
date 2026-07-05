// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public nonisolated struct GetTransactionsQuery: GraphQLQuery {
    public static let operationName: String = "GetTransactions"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
        definition: .init(
            #"query GetTransactions($ledgerId: ID, $filter: TransactionFilter, $limit: Int) { transactions(ledgerId: $ledgerId, filter: $filter, limit: $limit) { __typename id date narration amount { __typename value currencyCode } category merchant sourceFingerprint ledger { __typename id displayName } } }"#
        )
    )

    public var ledgerId: GraphQLNullable<ID>
    public var filter: GraphQLNullable<TransactionFilter>
    public var limit: GraphQLNullable<Int32>

    public init(
        ledgerId: GraphQLNullable<ID>,
        filter: GraphQLNullable<TransactionFilter>,
        limit: GraphQLNullable<Int32>
    ) {
        self.ledgerId = ledgerId
        self.filter = filter
        self.limit = limit
    }

    @_spi(Unsafe) public var __variables: Variables? {
        [
            "ledgerId": ledgerId,
            "filter": filter,
            "limit": limit
        ]
    }

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
                .field("transactions", [Transaction].self, arguments: [
                    "ledgerId": .variable("ledgerId"),
                    "filter": .variable("filter"),
                    "limit": .variable("limit")
                ])
            ]
        }

        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
            [
                GetTransactionsQuery.Data.self
            ]
        }

        public var transactions: [Transaction] {
            __data["transactions"]
        }

        /// Transaction
        ///
        /// Parent Type: `Transaction`
        public nonisolated struct Transaction: FinanceOSAPI.SelectionSet {
            @_spi(Unsafe) public let __data: DataDict
            @_spi(Unsafe)
            public init(_dataDict: DataDict) {
                __data = _dataDict
            }

            @_spi(Execution) public static var __parentType: any ApolloAPI
                .ParentType {
                FinanceOSAPI.Objects.Transaction
            }

            @_spi(Execution) public static var __selections: [ApolloAPI.Selection] {
                [
                    .field("__typename", String.self),
                    .field("id", FinanceOSAPI.ID.self),
                    .field("date", String.self),
                    .field("narration", String.self),
                    .field("amount", Amount.self),
                    .field("category", String?.self),
                    .field("merchant", String?.self),
                    .field("sourceFingerprint", String.self),
                    .field("ledger", Ledger.self)
                ]
            }

            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                [
                    GetTransactionsQuery.Data.Transaction.self
                ]
            }

            public var id: FinanceOSAPI.ID {
                __data["id"]
            }

            public var date: String {
                __data["date"]
            }

            public var narration: String {
                __data["narration"]
            }

            public var amount: Amount {
                __data["amount"]
            }

            public var category: String? {
                __data["category"]
            }

            public var merchant: String? {
                __data["merchant"]
            }

            public var sourceFingerprint: String {
                __data["sourceFingerprint"]
            }

            public var ledger: Ledger {
                __data["ledger"]
            }

            /// Transaction.Amount
            ///
            /// Parent Type: `Money`
            public nonisolated struct Amount: FinanceOSAPI.SelectionSet {
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
                        GetTransactionsQuery.Data.Transaction.Amount.self
                    ]
                }

                public var value: Int {
                    __data["value"]
                }

                public var currencyCode: GraphQLEnum<FinanceOSAPI.CurrencyCode> {
                    __data["currencyCode"]
                }
            }

            /// Transaction.Ledger
            ///
            /// Parent Type: `Ledger`
            public nonisolated struct Ledger: FinanceOSAPI.SelectionSet {
                @_spi(Unsafe) public let __data: DataDict
                @_spi(Unsafe)
                public init(_dataDict: DataDict) {
                    __data = _dataDict
                }

                @_spi(Execution) public static var __parentType: any ApolloAPI
                    .ParentType {
                    FinanceOSAPI.Objects.Ledger
                }

                @_spi(Execution) public static var __selections: [ApolloAPI.Selection] {
                    [
                        .field("__typename", String.self),
                        .field("id", FinanceOSAPI.ID.self),
                        .field("displayName", String.self)
                    ]
                }

                @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                    [
                        GetTransactionsQuery.Data.Transaction.Ledger.self
                    ]
                }

                public var id: FinanceOSAPI.ID {
                    __data["id"]
                }

                public var displayName: String {
                    __data["displayName"]
                }
            }
        }
    }
}
