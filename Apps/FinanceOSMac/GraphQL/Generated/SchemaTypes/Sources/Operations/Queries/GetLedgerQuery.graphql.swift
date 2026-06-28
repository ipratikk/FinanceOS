// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetLedgerQuery: GraphQLQuery {
    public static let operationName: String = "GetLedger"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
        definition: .init(
            #"query GetLedger($id: ID!) { ledger(id: $id) { __typename id displayName kind last4 bank { __typename id name code } balance } }"#
        )
    )

    public var id: ID

    public init(id: ID) {
        self.id = id
    }

    public var __variables: Variables? {
        ["id": id]
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
                .field("ledger", Ledger?.self, arguments: ["id": .variable("id")])
            ]
        }

        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
            [
                GetLedgerQuery.Data.self
            ]
        }

        public var ledger: Ledger? {
            __data["ledger"]
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
                    GetLedgerQuery.Data.Ledger.self
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
                        GetLedgerQuery.Data.Ledger.Bank.self
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
