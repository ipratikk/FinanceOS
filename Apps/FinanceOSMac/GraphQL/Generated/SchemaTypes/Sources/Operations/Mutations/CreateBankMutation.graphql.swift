// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public nonisolated struct CreateBankMutation: GraphQLMutation {
    public static let operationName: String = "CreateBank"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
        definition: .init(
            #"mutation CreateBank($input: CreateBankInput!) { createBank(input: $input) { __typename id name code } }"#
        )
    )

    public var input: CreateBankInput

    public init(input: CreateBankInput) {
        self.input = input
    }

    @_spi(Unsafe) public var __variables: Variables? {
        ["input": input]
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
                .field("createBank", CreateBank.self, arguments: ["input": .variable("input")])
            ]
        }

        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
            [
                CreateBankMutation.Data.self
            ]
        }

        public var createBank: CreateBank {
            __data["createBank"]
        }

        /// CreateBank
        ///
        /// Parent Type: `Bank`
        public nonisolated struct CreateBank: FinanceOSAPI.SelectionSet {
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
                    CreateBankMutation.Data.CreateBank.self
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
