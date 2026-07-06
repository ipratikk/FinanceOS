// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public nonisolated struct UploadStatementMutation: GraphQLMutation {
    public static let operationName: String = "UploadStatement"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
        definition: .init(
            #"mutation UploadStatement($ledgerId: ID!, $file: Upload!, $password: EncryptedPassword) { uploadStatement(ledgerId: $ledgerId, file: $file, password: $password) { __typename imported duplicates errors ledger { __typename id displayName balance { __typename value currencyCode } } } }"#
        )
    )

    public var ledgerId: ID
    public var file: Upload
    public var password: GraphQLNullable<EncryptedPassword>

    public init(
        ledgerId: ID,
        file: Upload,
        password: GraphQLNullable<EncryptedPassword>
    ) {
        self.ledgerId = ledgerId
        self.file = file
        self.password = password
    }

    @_spi(Unsafe) public var __variables: Variables? {
        [
            "ledgerId": ledgerId,
            "file": file,
            "password": password
        ]
    }

    public nonisolated struct Data: FinanceOSAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe)
        public init(_dataDict: DataDict) {
            __data = _dataDict
        }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType {
            FinanceOSAPI.Objects.Mutation
        }

        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] {
            [
                .field("uploadStatement", UploadStatement.self, arguments: [
                    "ledgerId": .variable("ledgerId"),
                    "file": .variable("file"),
                    "password": .variable("password")
                ])
            ]
        }

        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
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
        public nonisolated struct UploadStatement: FinanceOSAPI.SelectionSet {
            @_spi(Unsafe) public let __data: DataDict
            @_spi(Unsafe)
            public init(_dataDict: DataDict) {
                __data = _dataDict
            }

            @_spi(Execution) public static var __parentType: any ApolloAPI
                .ParentType {
                FinanceOSAPI.Objects.ImportResult
            }

            @_spi(Execution) public static var __selections: [ApolloAPI.Selection] {
                [
                    .field("__typename", String.self),
                    .field("imported", Int.self),
                    .field("duplicates", Int.self),
                    .field("errors", [String].self),
                    .field("ledger", Ledger.self)
                ]
            }

            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
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
                        .field("displayName", String.self),
                        .field("balance", Balance.self)
                    ]
                }

                @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
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

                public var balance: Balance {
                    __data["balance"]
                }

                /// UploadStatement.Ledger.Balance
                ///
                /// Parent Type: `Money`
                public nonisolated struct Balance: FinanceOSAPI.SelectionSet {
                    @_spi(Unsafe) public let __data: DataDict
                    @_spi(Unsafe)
                    public init(_dataDict: DataDict) {
                        __data = _dataDict
                    }

                    @_spi(Execution) public static var __parentType: any ApolloAPI
                        .ParentType {
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
                            UploadStatementMutation.Data.UploadStatement.Ledger.Balance.self
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
}
