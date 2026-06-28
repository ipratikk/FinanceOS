// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetTransactionsQuery: GraphQLQuery {
    public static let operationName: String = "GetTransactions"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
        definition: .init(
            #"query GetTransactions($ledgerId: ID, $filter: TransactionFilter, $limit: Int) { transactions(ledgerId: $ledgerId, filter: $filter, limit: $limit) { __typename id date narration amount category merchant sourceFingerprint ledger { __typename id displayName } } }"#
        )
    )

    public var ledgerId: GraphQLNullable<ID>
    public var filter: GraphQLNullable<TransactionFilter>
    public var limit: GraphQLNullable<Int>

    public init(
        ledgerId: GraphQLNullable<ID>,
        filter: GraphQLNullable<TransactionFilter>,
        limit: GraphQLNullable<Int>
    ) {
        self.ledgerId = ledgerId
        self.filter = filter
        self.limit = limit
    }

    public var __variables: Variables? {
        [
            "ledgerId": ledgerId,
            "filter": filter,
            "limit": limit
        ]
    }

    public struct Data: FinanceOSAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) {
            __data = _dataDict
        }

        public static var __parentType: any ApolloAPI.ParentType {
            FinanceOSAPI.Objects.Query
        }

        public static var __selections: [ApolloAPI.Selection] {
            [
                .field("transactions", [Transaction].self, arguments: [
                    "ledgerId": .variable("ledgerId"),
                    "filter": .variable("filter"),
                    "limit": .variable("limit")
                ])
            ]
        }

        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
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
        public struct Transaction: FinanceOSAPI.SelectionSet {
            public let __data: DataDict
            public init(_dataDict: DataDict) {
                __data = _dataDict
            }

            public static var __parentType: any ApolloAPI.ParentType {
                FinanceOSAPI.Objects.Transaction
            }

            public static var __selections: [ApolloAPI.Selection] {
                [
                    .field("__typename", String.self),
                    .field("id", FinanceOSAPI.ID.self),
                    .field("date", String.self),
                    .field("narration", String.self),
                    .field("amount", Double.self),
                    .field("category", String?.self),
                    .field("merchant", String?.self),
                    .field("sourceFingerprint", String.self),
                    .field("ledger", Ledger.self)
                ]
            }

            public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
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

            public var amount: Double {
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

            /// Transaction.Ledger
            ///
            /// Parent Type: `Ledger`
            public struct Ledger: FinanceOSAPI.SelectionSet {
                public let __data: DataDict
                public init(_dataDict: DataDict) {
                    __data = _dataDict
                }

                public static var __parentType: any ApolloAPI.ParentType {
                    FinanceOSAPI.Objects.Ledger
                }

                public static var __selections: [ApolloAPI.Selection] {
                    [
                        .field("__typename", String.self),
                        .field("id", FinanceOSAPI.ID.self),
                        .field("displayName", String.self)
                    ]
                }

                public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
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
