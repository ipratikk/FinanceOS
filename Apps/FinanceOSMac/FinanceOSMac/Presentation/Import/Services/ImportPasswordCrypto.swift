import CryptoKit
import Foundation

/// Seals a plaintext password for transmission to `financeos-backend` using
/// ephemeral-ECDH + HKDF-SHA256 + AES-256-GCM against the backend's permanent
/// public key. The plaintext password never leaves the device — only the
/// sealed envelope does. See docs/superpowers/specs/2026-07-06-password-protected-pdf-import-design.md.
enum ImportPasswordCrypto {
    struct SealedPassword {
        let ephemeralPublicKey: String
        let ciphertext: String
    }

    enum CryptoError: Error {
        case sealingFailed
    }

    /// Base64 X9.63 (0x04‖X‖Y, 65 bytes) representation of the backend's permanent P-256
    /// public key (private half lives only in node_api's IMPORT_PASSWORD_PRIVATE_KEY env
    /// var). Generated once via
    /// FinanceOS-Backend/node_api/scripts/generate-import-password-keypair.js — replace
    /// this value with your own deployment's output; it is safe to commit since it's
    /// public. Exposed separately from `backendPublicKey` (rather than only as a local
    /// inside it) so a test can assert this was actually replaced — see
    /// `ImportPasswordCryptoTests.test_backendPublicKey_placeholder_was_replaced`.
    static let backendPublicKeyBase64 =
        "BIak07nmXHaLIyzmq5rmDHk3Cmr+vhbRpoM3Fs0/DR5IcapOz80usj7AuJADLJHHUIKeLiMsHmYVuvCXS6oWpdo="

    static let backendPublicKey: P256.KeyAgreement.PublicKey = {
        guard let data = Data(base64Encoded: backendPublicKeyBase64),
              let key = try? P256.KeyAgreement.PublicKey(x963Representation: data) else {
            fatalError("ImportPasswordCrypto.backendPublicKeyBase64 is not a valid P-256 public key")
        }
        return key
    }()

    static func seal(
        _ password: String,
        recipientPublicKey: P256.KeyAgreement.PublicKey = backendPublicKey
    ) throws -> SealedPassword {
        let ephemeralPrivateKey = P256.KeyAgreement.PrivateKey()
        let sharedSecret = try ephemeralPrivateKey.sharedSecretFromKeyAgreement(with: recipientPublicKey)
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data("financeos-import-password-v1".utf8),
            outputByteCount: 32
        )
        let sealedBox = try AES.GCM.seal(Data(password.utf8), using: symmetricKey)
        guard let combined = sealedBox.combined else {
            throw CryptoError.sealingFailed
        }
        return SealedPassword(
            ephemeralPublicKey: ephemeralPrivateKey.publicKey.x963Representation.base64EncodedString(),
            ciphertext: combined.base64EncodedString()
        )
    }
}
