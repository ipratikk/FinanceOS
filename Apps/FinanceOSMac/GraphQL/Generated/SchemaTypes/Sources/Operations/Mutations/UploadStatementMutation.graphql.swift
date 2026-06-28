// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class UploadStatementMutation: GraphQLMutation {
    public static let operationName: String = "UploadStatement"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
        definition: .init(
            #"mutation UploadStatement($ledgerId: ID!, $file: Upload!) { uploadStatement(ledgerId: $ledgerId, file: $file) { __typename imported duplicates errors ledger { __typename id displayName balance } } }"#
        )
    )

    public var ledgerId: ID
    public var file: Upload

    public init(
        ledgerId: ID,
        file: Upload
    ) {
        self.ledgerId = ledgerId
        self.file = file
    }

    public var __variables: Variables? {
        [
            "ledgerId": ledgerId,
            "file": file
        ]
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
                .field("uploadStatement", UploadStatement.self, arguments: [
                    "ledgerId": .variable("ledgerId"),
                    "file": .variable("file")
                ])
            ]
        }

        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
            [
                UploadStatementMutation.Data.self
            ]
        }

        public var uploadStatement: UploadStatement {
            __data["uploadStatement"]
        }

        /// UploadStatement
        ///
        /// Parent Type: `ImportResult`
        public struct UploadStatement: FinanceOSAPI.SelectionSet {
            public let __data: DataDict
            public init(_dataDict: DataDict) {
                __data = _dataDict
            }

            public static var __parentType: any ApolloAPI.ParentType {
                FinanceOSAPI.Objects.ImportResult
            }

            public static var __selections: [ApolloAPI.Selection] {
                [
                    .field("__typename", String.self),
                    .field("imported", Int.self),
                    .field("duplicates", Int.self),
                    .field("errors", [String].self),
                    .field("ledger", Ledger.self)
                ]
            }

            public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                [
                    UploadStatementMutation.Data.UploadStatement.self
                ]
            }

            public var imported: Int {
                __data["imported"]
            }

            public var duplicates: Int {
                __data["duplicates"]
            }

            public var errors: [String] {
                __data["errors"]
            }

            public var ledger: Ledger {
                __data["ledger"]
            }

            /// UploadStatement.Ledger
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
                        .field("balance", Double.self)
                    ]
                }

                public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                    [
                        UploadStatementMutation.Data.UploadStatement.Ledger.self
                    ]
                }

                public var id: FinanceOSAPI.ID {
                    __data["id"]
                }

                public var displayName: String {
                    __data["displayName"]
                }

                public var balance: Double {
                    __data["balance"]
                }
            }
        }
    }
}
