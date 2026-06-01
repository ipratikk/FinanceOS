import Foundation

public struct MerchantGatewayConfig: Codable, Sendable {
    public let version: String
    public let tokens: [String]

    public static func load() -> MerchantGatewayConfig {
        guard let url = Bundle.module.url(forResource: "merchant_gateways", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(MerchantGatewayConfig.self, from: data) else {
            return .hardcodedFallback
        }
        return config
    }

    static let hardcodedFallback = MerchantGatewayConfig(
        version: "fallback",
        tokens: ["@rzp", "@razorpay", ".rzp", "bdsi@", ".payu@", "@ptybl", "@ptys", "@okbizaxis"]
    )
}
