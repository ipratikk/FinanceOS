// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class CreateLedgerMutation: GraphQLMutation {
    public static let operationName: String = "CreateLedger"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
        definition: .init(
            #"mutation CreateLedger($input: CreateLedgerInput!) { createLedger(input: $input) { __typename id displayName kind last4 bank { __typename id name } } }"#
        )
    )

    public var input: CreateLedgerInput

    public init(input: CreateLedgerInput) {
        self.input = input
    }

    public var __variables: Variables? {
        ["input": input]
    }

    public struct Data: FinanceOSAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) {
            __data = _dataDict
        }

        public static var __parentType: any ApolloAPI.ParentType {
            FinanceOSAPI.Objects.Mutation
        }

        public static var __selections: [ApolloAPI.Selection] {
            [
                .field("createLedger", CreateLedger.self, arguments: ["input": .variable("input")])
            ]
        }

        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
            [
                CreateLedgerMutation.Data.self
            ]
        }

        public var createLedger: CreateLedger {
            __data["createLedger"]
        }

        /// CreateLedger
        ///
        /// Parent Type: `Ledger`
        public struct CreateLedger: FinanceOSAPI.SelectionSet {
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
                    .field("bank", Bank.self)
                ]
            }

            public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                [
                    CreateLedgerMutation.Data.CreateLedger.self
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

            /// CreateLedger.Bank
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
                        .field("name", String.self)
                    ]
                }

                public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                    [
                        CreateLedgerMutation.Data.CreateLedger.Bank.self
                    ]
                }

                public var id: FinanceOSAPI.ID {
                    __data["id"]
                }

                public var name: String {
                    __data["name"]
                }
            }
        }
    }
}
