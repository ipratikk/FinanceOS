// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public nonisolated struct RecategorizeMutation: GraphQLMutation {
    public static let operationName: String = "Recategorize"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
        definition: .init(
            #"mutation Recategorize($transactionId: ID!, $category: String!) { recategorize(transactionId: $transactionId, category: $category) { __typename id category } }"#
        )
    )

    public var transactionId: ID
    public var category: String

    public init(
        transactionId: ID,
        category: String
    ) {
        self.transactionId = transactionId
        self.category = category
    }

    @_spi(Unsafe) public var __variables: Variables? {
        [
            "transactionId": transactionId,
            "category": category
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
                .field("recategorize", Recategorize.self, arguments: [
                    "transactionId": .variable("transactionId"),
                    "category": .variable("category")
                ])
            ]
        }

        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
            [
                RecategorizeMutation.Data.self
            ]
        }

        public var recategorize: Recategorize {
            __data["recategorize"]
        }

        /// Recategorize
        ///
        /// Parent Type: `Transaction`
        public nonisolated struct Recategorize: FinanceOSAPI.SelectionSet {
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
                    .field("category", String?.self)
                ]
            }

            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                [
                    RecategorizeMutation.Data.Recategorize.self
                ]
            }

            public var id: FinanceOSAPI.ID {
                __data["id"]
            }

            public var category: String? {
                __data["category"]
            }
        }
    }
}
