// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public nonisolated struct GetAnalyticsQuery: GraphQLQuery {
    public static let operationName: String = "GetAnalytics"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
        definition: .init(
            #"query GetAnalytics($ledgerId: ID, $from: String, $to: String) { analytics(ledgerId: $ledgerId, from: $from, to: $to) { __typename totalSpend { __typename value currencyCode } totalIncome { __typename value currencyCode } netFlow { __typename value currencyCode } byCategory { __typename category amount { __typename value currencyCode } count } byMonth { __typename month spend { __typename value currencyCode } income { __typename value currencyCode } } } }"#
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

    @_spi(Unsafe) public var __variables: Variables? {
        [
            "ledgerId": ledgerId,
            "from": from,
            "to": to
        ]
    }

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
                .field("analytics", Analytics.self, arguments: [
                    "ledgerId": .variable("ledgerId"),
                    "from": .variable("from"),
                    "to": .variable("to")
                ])
            ]
        }

        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
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
        public nonisolated struct Analytics: FinanceOSAPI.SelectionSet {
            @_spi(Unsafe) public let __data: DataDict
            @_spi(Unsafe)
            public init(_dataDict: DataDict) {
                __data = _dataDict
            }

            @_spi(Execution) public static var __parentType: any ApolloAPI
                .ParentType {
                FinanceOSAPI.Objects.SpendingSummary
            }

            @_spi(Execution) public static var __selections: [ApolloAPI.Selection] {
                [
                    .field("__typename", String.self),
                    .field("totalSpend", TotalSpend.self),
                    .field("totalIncome", TotalIncome.self),
                    .field("netFlow", NetFlow.self),
                    .field("byCategory", [ByCategory].self),
                    .field("byMonth", [ByMonth].self)
                ]
            }

            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                [
                    GetAnalyticsQuery.Data.Analytics.self
                ]
            }

            public var totalSpend: TotalSpend {
                __data["totalSpend"]
            }

            public var totalIncome: TotalIncome {
                __data["totalIncome"]
            }

            public var netFlow: NetFlow {
                __data["netFlow"]
            }

            public var byCategory: [ByCategory] {
                __data["byCategory"]
            }

            public var byMonth: [ByMonth] {
                __data["byMonth"]
            }

            /// Analytics.TotalSpend
            ///
            /// Parent Type: `Money`
            public nonisolated struct TotalSpend: FinanceOSAPI.SelectionSet {
                @_spi(Unsafe) public let __data: DataDict
                @_spi(Unsafe)
                public init(_dataDict: DataDict) {
                    __data = _dataDict
                }

                @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType {
                    FinanceOSAPI.Objects.Money
                }

                @_spi(Execution) public static var __selections: [ApolloAPI.Selection] {
                    [
                        .field("__typename", String.self),
                        .field("value", Int.self),
                        .field("currencyCode", GraphQLEnum<FinanceOSAPI.CurrencyCode>.self)
                    ]
                }

                @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                    [
                        GetAnalyticsQuery.Data.Analytics.TotalSpend.self
                    ]
                }

                public var value: Int {
                    __data["value"]
                }

                public var currencyCode: GraphQLEnum<FinanceOSAPI.CurrencyCode> {
                    __data["currencyCode"]
                }
            }

            /// Analytics.TotalIncome
            ///
            /// Parent Type: `Money`
            public nonisolated struct TotalIncome: FinanceOSAPI.SelectionSet {
                @_spi(Unsafe) public let __data: DataDict
                @_spi(Unsafe)
                public init(_dataDict: DataDict) {
                    __data = _dataDict
                }

                @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType {
                    FinanceOSAPI.Objects.Money
                }

                @_spi(Execution) public static var __selections: [ApolloAPI.Selection] {
                    [
                        .field("__typename", String.self),
                        .field("value", Int.self),
                        .field("currencyCode", GraphQLEnum<FinanceOSAPI.CurrencyCode>.self)
                    ]
                }

                @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                    [
                        GetAnalyticsQuery.Data.Analytics.TotalIncome.self
                    ]
                }

                public var value: Int {
                    __data["value"]
                }

                public var currencyCode: GraphQLEnum<FinanceOSAPI.CurrencyCode> {
                    __data["currencyCode"]
                }
            }

            /// Analytics.NetFlow
            ///
            /// Parent Type: `Money`
            public nonisolated struct NetFlow: FinanceOSAPI.SelectionSet {
                @_spi(Unsafe) public let __data: DataDict
                @_spi(Unsafe)
                public init(_dataDict: DataDict) {
                    __data = _dataDict
                }

                @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType {
                    FinanceOSAPI.Objects.Money
                }

                @_spi(Execution) public static var __selections: [ApolloAPI.Selection] {
                    [
                        .field("__typename", String.self),
                        .field("value", Int.self),
                        .field("currencyCode", GraphQLEnum<FinanceOSAPI.CurrencyCode>.self)
                    ]
                }

                @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                    [
                        GetAnalyticsQuery.Data.Analytics.NetFlow.self
                    ]
                }

                public var value: Int {
                    __data["value"]
                }

                public var currencyCode: GraphQLEnum<FinanceOSAPI.CurrencyCode> {
                    __data["currencyCode"]
                }
            }

            /// Analytics.ByCategory
            ///
            /// Parent Type: `CategoryBreakdown`
            public nonisolated struct ByCategory: FinanceOSAPI.SelectionSet {
                @_spi(Unsafe) public let __data: DataDict
                @_spi(Unsafe)
                public init(_dataDict: DataDict) {
                    __data = _dataDict
                }

                @_spi(Execution) public static var __parentType: any ApolloAPI
                    .ParentType {
                    FinanceOSAPI.Objects.CategoryBreakdown
                }

                @_spi(Execution) public static var __selections: [ApolloAPI.Selection] {
                    [
                        .field("__typename", String.self),
                        .field("category", String.self),
                        .field("amount", Amount.self),
                        .field("count", Int.self)
                    ]
                }

                @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                    [
                        GetAnalyticsQuery.Data.Analytics.ByCategory.self
                    ]
                }

                public var category: String {
                    __data["category"]
                }

                public var amount: Amount {
                    __data["amount"]
                }

                public var count: Int {
                    __data["count"]
                }

                /// Analytics.ByCategory.Amount
                ///
                /// Parent Type: `Money`
                public nonisolated struct Amount: FinanceOSAPI.SelectionSet {
                    @_spi(Unsafe) public let __data: DataDict
                    @_spi(Unsafe)
                    public init(_dataDict: DataDict) {
                        __data = _dataDict
                    }

                    @_spi(Execution) public static var __parentType: any ApolloAPI
                        .ParentType {
                        FinanceOSAPI.Objects.Money
                    }

                    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] {
                        [
                            .field("__typename", String.self),
                            .field("value", Int.self),
                            .field("currencyCode", GraphQLEnum<FinanceOSAPI.CurrencyCode>.self)
                        ]
                    }

                    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                        [
                            GetAnalyticsQuery.Data.Analytics.ByCategory.Amount.self
                        ]
                    }

                    public var value: Int {
                        __data["value"]
                    }

                    public var currencyCode: GraphQLEnum<FinanceOSAPI.CurrencyCode> {
                        __data["currencyCode"]
                    }
                }
            }

            /// Analytics.ByMonth
            ///
            /// Parent Type: `MonthlyBreakdown`
            public nonisolated struct ByMonth: FinanceOSAPI.SelectionSet {
                @_spi(Unsafe) public let __data: DataDict
                @_spi(Unsafe)
                public init(_dataDict: DataDict) {
                    __data = _dataDict
                }

                @_spi(Execution) public static var __parentType: any ApolloAPI
                    .ParentType {
                    FinanceOSAPI.Objects.MonthlyBreakdown
                }

                @_spi(Execution) public static var __selections: [ApolloAPI.Selection] {
                    [
                        .field("__typename", String.self),
                        .field("month", String.self),
                        .field("spend", Spend.self),
                        .field("income", Income.self)
                    ]
                }

                @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                    [
                        GetAnalyticsQuery.Data.Analytics.ByMonth.self
                    ]
                }

                public var month: String {
                    __data["month"]
                }

                public var spend: Spend {
                    __data["spend"]
                }

                public var income: Income {
                    __data["income"]
                }

                /// Analytics.ByMonth.Spend
                ///
                /// Parent Type: `Money`
                public nonisolated struct Spend: FinanceOSAPI.SelectionSet {
                    @_spi(Unsafe) public let __data: DataDict
                    @_spi(Unsafe)
                    public init(_dataDict: DataDict) {
                        __data = _dataDict
                    }

                    @_spi(Execution) public static var __parentType: any ApolloAPI
                        .ParentType {
                        FinanceOSAPI.Objects.Money
                    }

                    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] {
                        [
                            .field("__typename", String.self),
                            .field("value", Int.self),
                            .field("currencyCode", GraphQLEnum<FinanceOSAPI.CurrencyCode>.self)
                        ]
                    }

                    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                        [
                            GetAnalyticsQuery.Data.Analytics.ByMonth.Spend.self
                        ]
                    }

                    public var value: Int {
                        __data["value"]
                    }

                    public var currencyCode: GraphQLEnum<FinanceOSAPI.CurrencyCode> {
                        __data["currencyCode"]
                    }
                }

                /// Analytics.ByMonth.Income
                ///
                /// Parent Type: `Money`
                public nonisolated struct Income: FinanceOSAPI.SelectionSet {
                    @_spi(Unsafe) public let __data: DataDict
                    @_spi(Unsafe)
                    public init(_dataDict: DataDict) {
                        __data = _dataDict
                    }

                    @_spi(Execution) public static var __parentType: any ApolloAPI
                        .ParentType {
                        FinanceOSAPI.Objects.Money
                    }

                    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] {
                        [
                            .field("__typename", String.self),
                            .field("value", Int.self),
                            .field("currencyCode", GraphQLEnum<FinanceOSAPI.CurrencyCode>.self)
                        ]
                    }

                    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                        [
                            GetAnalyticsQuery.Data.Analytics.ByMonth.Income.self
                        ]
                    }

                    public var value: Int {
                        __data["value"]
                    }

                    public var currencyCode: GraphQLEnum<FinanceOSAPI.CurrencyCode> {
                        __data["currencyCode"]
                    }
                }
            }
        }
    }
}
