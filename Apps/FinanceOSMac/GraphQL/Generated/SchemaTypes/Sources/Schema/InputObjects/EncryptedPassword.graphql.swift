// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

public nonisolated struct EncryptedPassword: InputObject {
    @_spi(Unsafe) public private(set) var __data: InputDict

    @_spi(Unsafe)
    public init(_ data: InputDict) {
        __data = data
    }

    public init(
        ephemeralPublicKey: String,
        ciphertext: String
    ) {
        __data = InputDict([
            "ephemeralPublicKey": ephemeralPublicKey,
            "ciphertext": ciphertext
        ])
    }

    public var ephemeralPublicKey: String {
        get { __data["ephemeralPublicKey"] }
        set { __data["ephemeralPublicKey"] = newValue }
    }

    public var ciphertext: String {
        get { __data["ciphertext"] }
        set { __data["ciphertext"] = newValue }
    }
}
