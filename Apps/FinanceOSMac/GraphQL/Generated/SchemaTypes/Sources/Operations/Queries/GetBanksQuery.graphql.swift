// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetBanksQuery: GraphQLQuery {
    public static let operationName: String = "GetBanks"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
        definition: .init(
            #"query GetBanks { banks { __typename id name code } }"#
        )
    )

    public init() {}

    public struct Data: FinanceOSAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) {
            __data = _dataDict
        }

        public static var __parentType: any ApolloAPI.ParentType {
            FinanceOSAPI.Objects.Query
        }

        public static var __selections: [ApolloAPI.Selection] {
            [
                .field("banks", [Bank].self)
            ]
        }

        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
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
        public struct Bank: FinanceOSAPI.SelectionSet {
            public let __data: DataDict
            public init(_dataDict: DataDict) {
                __data = _dataDict
            }

            public static var __parentType: any ApolloAPI.ParentType {
                FinanceOSAPI.Objects.Bank
            }

            public static var __selections: [ApolloAPI.Selection] {
                [
                    .field("__typename", String.self),
                    .field("id", FinanceOSAPI.ID.self),
                    .field("name", String.self),
                    .field("code", String.self)
                ]
            }

            public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
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
