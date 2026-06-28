// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetLedgersQuery: GraphQLQuery {
    public static let operationName: String = "GetLedgers"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
        definition: .init(
            #"query GetLedgers { ledgers { __typename id displayName kind last4 bank { __typename id name code } balance } }"#
        )
    )

    public init() {}

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
                .field("ledgers", [Ledger].self)
            ]
        }

        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
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
                    .field("displayName", String.self),
                    .field("kind", GraphQLEnum<FinanceOSAPI.LedgerKind>.self),
                    .field("last4", String?.self),
                    .field("bank", Bank.self),
                    .field("balance", Double.self)
                ]
            }

            public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
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

            public var balance: Double {
                __data["balance"]
            }

            /// Ledger.Bank
            ///
            /// Parent Type: `Bank`
            public struct Bank: FinanceOSAPI.SelectionSet {
                public let __data: DataDict
                public init(_dataDict: DataDict) {
                    __data = _dataDict
                }

                public static var __parentType: any ApolloAPI.ParentType {
                    FinanceOSAPI.Objects.Bank
                }

                public static var __selections: [ApolloAPI.Selection] {
                    [
                        .field("__typename", String.self),
                        .field("id", FinanceOSAPI.ID.self),
                        .field("name", String.self),
                        .field("code", String.self)
                    ]
                }

                public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
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
        }
    }
}
