// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public nonisolated struct ClearAllDataMutation: GraphQLMutation {
    public static let operationName: String = "ClearAllData"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
        definition: .init(
            #"mutation ClearAllData { clearAllData }"#
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
            FinanceOSAPI.Objects.Mutation
        }

        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] {
            [
                .field("clearAllData", Bool.self)
            ]
        }

        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
            [
                ClearAllDataMutation.Data.self
            ]
        }

        public var clearAllData: Bool {
            __data["clearAllData"]
        }
    }
}
