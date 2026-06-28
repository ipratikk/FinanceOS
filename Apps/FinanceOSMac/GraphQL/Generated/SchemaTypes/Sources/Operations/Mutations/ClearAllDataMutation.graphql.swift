// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class ClearAllDataMutation: GraphQLMutation {
    public static let operationName: String = "ClearAllData"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
        definition: .init(
            #"mutation ClearAllData { clearAllData }"#
        )
    )

    public init() {}

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
                .field("clearAllData", Bool.self)
            ]
        }

        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
            [
                ClearAllDataMutation.Data.self
            ]
        }

        public var clearAllData: Bool {
            __data["clearAllData"]
        }
    }
}
