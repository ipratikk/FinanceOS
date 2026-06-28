// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public struct CreateLedgerInput: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
        __data = data
    }

    public init(
        displayName: String,
        kind: GraphQLEnum<LedgerKind>,
        last4: GraphQLNullable<String> = nil,
        bankId: ID
    ) {
        __data = InputDict([
            "displayName": displayName,
            "kind": kind,
            "last4": last4,
            "bankId": bankId
        ])
    }

    public var displayName: String {
        get { __data["displayName"] }
        set { __data["displayName"] = newValue }
    }

    public var kind: GraphQLEnum<LedgerKind> {
        get { __data["kind"] }
        set { __data["kind"] = newValue }
    }

    public var last4: GraphQLNullable<String> {
        get { __data["last4"] }
        set { __data["last4"] = newValue }
    }

    public var bankId: ID {
        get { __data["bankId"] }
        set { __data["bankId"] = newValue }
    }
}
