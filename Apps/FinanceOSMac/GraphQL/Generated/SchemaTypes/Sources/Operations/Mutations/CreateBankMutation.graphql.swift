// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class CreateBankMutation: GraphQLMutation {
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

    public var __variables: Variables? {
        ["input": input]
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
                .field("createBank", CreateBank.self, arguments: ["input": .variable("input")])
            ]
        }

        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
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
        public struct CreateBank: FinanceOSAPI.SelectionSet {
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
