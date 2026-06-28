// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public struct CreateBankInput: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
        __data = data
    }

    public init(
        name: String,
        code: String
    ) {
        __data = InputDict([
            "name": name,
            "code": code
        ])
    }

    public var name: String {
        get { __data["name"] }
        set { __data["name"] = newValue }
    }

    public var code: String {
        get { __data["code"] }
        set { __data["code"] = newValue }
    }
}
