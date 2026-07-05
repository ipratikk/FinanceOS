// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public nonisolated struct GetBanksQuery: GraphQLQuery {
    public static let operationName: String = "GetBanks"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
        definition: .init(
            #"query GetBanks { banks { __typename id name code } }"#
        )
    )

    public init() {}

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
                .field("banks", [Bank].self)
            ]
        }

        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
            [
                GetBanksQuery.Data.self
            ]
        }

        public var banks: [Bank] {
            __data["banks"]
        }

        /// Bank
        ///
        /// Parent Type: `Bank`
        public nonisolated struct Bank: FinanceOSAPI.SelectionSet {
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
                    GetBanksQuery.Data.Bank.self
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
