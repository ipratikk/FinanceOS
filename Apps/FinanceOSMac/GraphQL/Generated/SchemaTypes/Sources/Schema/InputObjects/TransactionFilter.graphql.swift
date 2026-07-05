// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

public nonisolated struct TransactionFilter: InputObject {
    @_spi(Unsafe) public private(set) var __data: InputDict

    @_spi(Unsafe)
    public init(_ data: InputDict) {
        __data = data
    }

    public init(
        from: GraphQLNullable<String> = nil,
        to: GraphQLNullable<String> = nil,
        category: GraphQLNullable<String> = nil,
        minAmount: GraphQLNullable<Int32> = nil,
        maxAmount: GraphQLNullable<Int32> = nil
    ) {
        __data = InputDict([
            "from": from,
            "to": to,
            "category": category,
            "minAmount": minAmount,
            "maxAmount": maxAmount
        ])
    }

    public var from: GraphQLNullable<String> {
        get { __data["from"] }
        set { __data["from"] = newValue }
    }

    public var to: GraphQLNullable<String> {
        get { __data["to"] }
        set { __data["to"] = newValue }
    }

    public var category: GraphQLNullable<String> {
        get { __data["category"] }
        set { __data["category"] = newValue }
    }

    public var minAmount: GraphQLNullable<Int32> {
        get { __data["minAmount"] }
        set { __data["minAmount"] = newValue }
    }

    public var maxAmount: GraphQLNullable<Int32> {
        get { __data["maxAmount"] }
        set { __data["maxAmount"] = newValue }
    }
}
