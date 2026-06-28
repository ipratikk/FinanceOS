// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class DeleteTransactionMutation: GraphQLMutation {
    public static let operationName: String = "DeleteTransaction"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
        definition: .init(
            #"mutation DeleteTransaction($id: ID!) { deleteTransaction(id: $id) }"#
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
            FinanceOSAPI.Objects.Mutation
        }

        public static var __selections: [ApolloAPI.Selection] {
            [
                .field("deleteTransaction", Bool.self, arguments: ["id": .variable("id")])
            ]
        }

        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
            [
                DeleteTransactionMutation.Data.self
            ]
        }

        public var deleteTransaction: Bool {
            __data["deleteTransaction"]
        }
    }
}
