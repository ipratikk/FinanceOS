// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public nonisolated struct DeleteLedgerMutation: GraphQLMutation {
    public static let operationName: String = "DeleteLedger"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
        definition: .init(
            #"mutation DeleteLedger($id: ID!) { deleteLedger(id: $id) }"#
        )
    )

    public var id: ID

    public init(id: ID) {
        self.id = id
    }

    @_spi(Unsafe) public var __variables: Variables? {
        ["id": id]
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
                .field("deleteLedger", Bool.self, arguments: ["id": .variable("id")])
            ]
        }

        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
            [
                DeleteLedgerMutation.Data.self
            ]
        }

        public var deleteLedger: Bool {
            __data["deleteLedger"]
        }
    }
}
