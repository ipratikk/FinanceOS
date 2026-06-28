// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class DeleteLedgerMutation: GraphQLMutation {
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
                .field("deleteLedger", Bool.self, arguments: ["id": .variable("id")])
            ]
        }

        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
            [
                DeleteLedgerMutation.Data.self
            ]
        }

        public var deleteLedger: Bool {
            __data["deleteLedger"]
        }
    }
}
