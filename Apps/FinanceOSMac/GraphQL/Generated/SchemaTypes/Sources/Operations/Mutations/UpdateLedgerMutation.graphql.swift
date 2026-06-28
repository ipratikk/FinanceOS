// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class UpdateLedgerMutation: GraphQLMutation {
    public static let operationName: String = "UpdateLedger"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
        definition: .init(
            #"mutation UpdateLedger($id: ID!, $input: UpdateLedgerInput!) { updateLedger(id: $id, input: $input) { __typename id displayName kind last4 } }"#
        )
    )

    public var id: ID
    public var input: UpdateLedgerInput

    public init(
        id: ID,
        input: UpdateLedgerInput
    ) {
        self.id = id
        self.input = input
    }

    public var __variables: Variables? {
        [
            "id": id,
            "input": input
        ]
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
                .field("updateLedger", UpdateLedger.self, arguments: [
                    "id": .variable("id"),
                    "input": .variable("input")
                ])
            ]
        }

        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
            [
                UpdateLedgerMutation.Data.self
            ]
        }

        public var updateLedger: UpdateLedger {
            __data["updateLedger"]
        }

        /// UpdateLedger
        ///
        /// Parent Type: `Ledger`
        public struct UpdateLedger: FinanceOSAPI.SelectionSet {
            public let __data: DataDict
            public init(_dataDict: DataDict) {
                __data = _dataDict
            }

            public static var __parentType: any ApolloAPI.ParentType {
                FinanceOSAPI.Objects.Ledger
            }

            public static var __selections: [ApolloAPI.Selection] {
                [
                    .field("__typename", String.self),
                    .field("id", FinanceOSAPI.ID.self),
                    .field("displayName", String.self),
                    .field("kind", GraphQLEnum<FinanceOSAPI.LedgerKind>.self),
                    .field("last4", String?.self)
                ]
            }

            public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                [
                    UpdateLedgerMutation.Data.UpdateLedger.self
                ]
            }

            public var id: FinanceOSAPI.ID {
                __data["id"]
            }

            public var displayName: String {
                __data["displayName"]
            }

            public var kind: GraphQLEnum<FinanceOSAPI.LedgerKind> {
                __data["kind"]
            }

            public var last4: String? {
                __data["last4"]
            }
        }
    }
}
