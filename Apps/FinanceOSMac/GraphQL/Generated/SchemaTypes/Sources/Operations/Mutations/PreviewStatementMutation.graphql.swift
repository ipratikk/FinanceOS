// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public nonisolated struct PreviewStatementMutation: GraphQLMutation {
    public static let operationName: String = "PreviewStatement"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
        definition: .init(
            #"mutation PreviewStatement($file: Upload!, $password: EncryptedPassword) { previewStatement(file: $file, password: $password) { __typename bankCode last4 transactionCount passwordRequired } }"#
        )
    )

    public var file: Upload
    public var password: GraphQLNullable<EncryptedPassword>

    public init(
        file: Upload,
        password: GraphQLNullable<EncryptedPassword>
    ) {
        self.file = file
        self.password = password
    }

    @_spi(Unsafe) public var __variables: Variables? {
        [
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
                .field("previewStatement", PreviewStatement.self, arguments: [
                    "file": .variable("file"),
                    "password": .variable("password")
                ])
            ]
        }

        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
            [
                PreviewStatementMutation.Data.self
            ]
        }

        public var previewStatement: PreviewStatement {
            __data["previewStatement"]
        }

        /// PreviewStatement
        ///
        /// Parent Type: `StatementPreview`
        public nonisolated struct PreviewStatement: FinanceOSAPI.SelectionSet {
            @_spi(Unsafe) public let __data: DataDict
            @_spi(Unsafe)
            public init(_dataDict: DataDict) {
                __data = _dataDict
            }

            @_spi(Execution) public static var __parentType: any ApolloAPI
                .ParentType {
                FinanceOSAPI.Objects.StatementPreview
            }

            @_spi(Execution) public static var __selections: [ApolloAPI.Selection] {
                [
                    .field("__typename", String.self),
                    .field("bankCode", String.self),
                    .field("last4", String?.self),
                    .field("transactionCount", Int.self),
                    .field("passwordRequired", Bool.self)
                ]
            }

            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                [
                    PreviewStatementMutation.Data.PreviewStatement.self
                ]
            }

            public var bankCode: String {
                __data["bankCode"]
            }

            public var last4: String? {
                __data["last4"]
            }

            public var transactionCount: Int {
                __data["transactionCount"]
            }

            public var passwordRequired: Bool {
                __data["passwordRequired"]
            }
        }
    }
}
