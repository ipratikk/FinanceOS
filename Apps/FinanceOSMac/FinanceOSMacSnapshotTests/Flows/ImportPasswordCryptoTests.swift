import CryptoKit
@testable import FinanceOSMac
import XCTest

final class ImportPasswordCryptoTests: XCTestCase {
    // Fixed test-only fixture values — the same ones verified against Node's
    // `crypto` module in FinanceOS-Backend's passwordCrypto.test.ts. This is
    // NOT the real deployment keypair (never committed anywhere).
    private let ephemeralPrivateRawBase64 = "ZDnlXSkWgS3aWEtJ/5w1U4C4M8gzJ46LMWMN2sVyPfE="
    private let backendPublicRawBase64 =
        "BJb0lVFCWMLnP8Aoxk1VVu3ECfSkoUL8oknzkukL8Ten0NOCd5DIjbxNEWt+lJfpkgSAJm1W21N93n8BSJiYHR4="
    private let expectedSharedSecretBase64 = "ZGTr5gsbVCrhJcPDLrX5n1wwbkbGK6Y/NQsREauI7oU="
    private let expectedAESKeyBase64 = "pslNMm2AcUhIunmNH7WrPSOdAe0bc8Cjol0Q92HpzY8="

    func test_ecdh_and_hkdf_match_node_fixture() throws {
        let ephemeralPrivateKey = try P256.KeyAgreement.PrivateKey(
            rawRepresentation: XCTUnwrap(Data(base64Encoded: ephemeralPrivateRawBase64))
        )
        let backendPublicKey = try P256.KeyAgreement.PublicKey(
            x963Representation: XCTUnwrap(Data(base64Encoded: backendPublicRawBase64))
        )

        let sharedSecret = try ephemeralPrivateKey.sharedSecretFromKeyAgreement(with: backendPublicKey)
        let sharedSecretData = sharedSecret.withUnsafeBytes { Data($0) }
        XCTAssertEqual(
            sharedSecretData.base64EncodedString(), expectedSharedSecretBase64,
            "ECDH shared secret mismatch — check x963 vs raw public-key encoding first"
        )

        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data("financeos-import-password-v1".utf8),
            outputByteCount: 32
        )
        let keyData = symmetricKey.withUnsafeBytes { Data($0) }
        XCTAssertEqual(
            keyData.base64EncodedString(), expectedAESKeyBase64,
            "HKDF output mismatch — check salt/info string match Node's exactly"
        )
    }

    func test_seal_produces_a_ciphertext_the_recipient_can_decrypt() throws {
        // Simulate "the backend": a locally-generated test keypair, never the real one.
        let testRecipientPrivateKey = P256.KeyAgreement.PrivateKey()
        let sealed = try ImportPasswordCrypto.seal(
            "correct horse battery staple",
            recipientPublicKey: testRecipientPrivateKey.publicKey
        )

        let ephemeralPublicKey = try P256.KeyAgreement.PublicKey(
            x963Representation: XCTUnwrap(Data(base64Encoded: sealed.ephemeralPublicKey))
        )
        let sharedSecret = try testRecipientPrivateKey.sharedSecretFromKeyAgreement(with: ephemeralPublicKey)
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data("financeos-import-password-v1".utf8),
            outputByteCount: 32
        )
        let combined = try XCTUnwrap(Data(base64Encoded: sealed.ciphertext))
        let sealedBox = try AES.GCM.SealedBox(combined: combined)
        let decrypted = try AES.GCM.open(sealedBox, using: symmetricKey)

        XCTAssertEqual(String(data: decrypted, encoding: .utf8), "correct horse battery staple")
    }

    func test_backendPublicKey_placeholder_was_replaced() {
        XCTAssertNotEqual(
            ImportPasswordCrypto.backendPublicKeyBase64,
            "REPLACE_WITH_YOUR_GENERATED_PUBLIC_KEY_FROM_TASK_3_STEP_2",
            "ImportPasswordCrypto.backendPublicKeyBase64 still has its placeholder value — " +
                "replace it with the public key generated in Task 3, Step 2"
        )
        XCTAssertNoThrow(try {
            let data = try XCTUnwrap(Data(base64Encoded: ImportPasswordCrypto.backendPublicKeyBase64))
            _ = try P256.KeyAgreement.PublicKey(x963Representation: data)
        }())
    }
}
