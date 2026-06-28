// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetAnalyticsQuery: GraphQLQuery {
    public static let operationName: String = "GetAnalytics"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
        definition: .init(
            #"query GetAnalytics($ledgerId: ID, $from: String, $to: String) { analytics(ledgerId: $ledgerId, from: $from, to: $to) { __typename totalSpend totalIncome netFlow byCategory { __typename category amount count } byMonth { __typename month spend income } } }"#
        )
    )

    public var ledgerId: GraphQLNullable<ID>
    public var from: GraphQLNullable<String>
    public var to: GraphQLNullable<String>

    public init(
        ledgerId: GraphQLNullable<ID>,
        from: GraphQLNullable<String>,
        to: GraphQLNullable<String>
    ) {
        self.ledgerId = ledgerId
        self.from = from
        self.to = to
    }

    public var __variables: Variables? {
        [
            "ledgerId": ledgerId,
            "from": from,
            "to": to
        ]
    }

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
                .field("analytics", Analytics.self, arguments: [
                    "ledgerId": .variable("ledgerId"),
                    "from": .variable("from"),
                    "to": .variable("to")
                ])
            ]
        }

        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
            [
                GetAnalyticsQuery.Data.self
            ]
        }

        public var analytics: Analytics {
            __data["analytics"]
        }

        /// Analytics
        ///
        /// Parent Type: `SpendingSummary`
        public struct Analytics: FinanceOSAPI.SelectionSet {
            public let __data: DataDict
            public init(_dataDict: DataDict) {
                __data = _dataDict
            }

            public static var __parentType: any ApolloAPI.ParentType {
                FinanceOSAPI.Objects.SpendingSummary
            }

            public static var __selections: [ApolloAPI.Selection] {
                [
                    .field("__typename", String.self),
                    .field("totalSpend", Double.self),
                    .field("totalIncome", Double.self),
                    .field("netFlow", Double.self),
                    .field("byCategory", [ByCategory].self),
                    .field("byMonth", [ByMonth].self)
                ]
            }

            public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                [
                    GetAnalyticsQuery.Data.Analytics.self
                ]
            }

            public var totalSpend: Double {
                __data["totalSpend"]
            }

            public var totalIncome: Double {
                __data["totalIncome"]
            }

            public var netFlow: Double {
                __data["netFlow"]
            }

            public var byCategory: [ByCategory] {
                __data["byCategory"]
            }

            public var byMonth: [ByMonth] {
                __data["byMonth"]
            }

            /// Analytics.ByCategory
            ///
            /// Parent Type: `CategoryBreakdown`
            public struct ByCategory: FinanceOSAPI.SelectionSet {
                public let __data: DataDict
                public init(_dataDict: DataDict) {
                    __data = _dataDict
                }

                public static var __parentType: any ApolloAPI.ParentType {
                    FinanceOSAPI.Objects.CategoryBreakdown
                }

                public static var __selections: [ApolloAPI.Selection] {
                    [
                        .field("__typename", String.self),
                        .field("category", String.self),
                        .field("amount", Double.self),
                        .field("count", Int.self)
                    ]
                }

                public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                    [
                        GetAnalyticsQuery.Data.Analytics.ByCategory.self
                    ]
                }

                public var category: String {
                    __data["category"]
                }

                public var amount: Double {
                    __data["amount"]
                }

                public var count: Int {
                    __data["count"]
                }
            }

            /// Analytics.ByMonth
            ///
            /// Parent Type: `MonthlyBreakdown`
            public struct ByMonth: FinanceOSAPI.SelectionSet {
                public let __data: DataDict
                public init(_dataDict: DataDict) {
                    __data = _dataDict
                }

                public static var __parentType: any ApolloAPI.ParentType {
                    FinanceOSAPI.Objects.MonthlyBreakdown
                }

                public static var __selections: [ApolloAPI.Selection] {
                    [
                        .field("__typename", String.self),
                        .field("month", String.self),
                        .field("spend", Double.self),
                        .field("income", Double.self)
                    ]
                }

                public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                    [
                        GetAnalyticsQuery.Data.Analytics.ByMonth.self
                    ]
                }

                public var month: String {
                    __data["month"]
                }

                public var spend: Double {
                    __data["spend"]
                }

                public var income: Double {
                    __data["income"]
                }
            }
        }
    }
}
