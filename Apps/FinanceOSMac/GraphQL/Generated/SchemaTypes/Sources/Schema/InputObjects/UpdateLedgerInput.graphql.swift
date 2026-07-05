// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

public nonisolated struct UpdateLedgerInput: InputObject {
    @_spi(Unsafe) public private(set) var __data: InputDict

    @_spi(Unsafe)
    public init(_ data: InputDict) {
        __data = data
    }

    public init(
        displayName: GraphQLNullable<String> = nil,
        kind: GraphQLNullable<GraphQLEnum<LedgerKind>> = nil,
        last4: GraphQLNullable<String> = nil
    ) {
        __data = InputDict([
            "displayName": displayName,
            "kind": kind,
            "last4": last4
        ])
    }

    public var displayName: GraphQLNullable<String> {
        get { __data["displayName"] }
        set { __data["displayName"] = newValue }
    }

    public var kind: GraphQLNullable<GraphQLEnum<LedgerKind>> {
        get { __data["kind"] }
        set { __data["kind"] = newValue }
    }

    public var last4: GraphQLNullable<String> {
        get { __data["last4"] }
        set { __data["last4"] = newValue }
    }
}
