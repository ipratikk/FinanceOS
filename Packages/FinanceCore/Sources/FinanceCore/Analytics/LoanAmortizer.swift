import Foundation

/// Splits EMI payments into principal and interest components.
/// Used for accurate expense tracking (only interest counts as expense).
public struct LoanAmortizer {
    public struct AmortizedPayment: Sendable {
        public let principalMinorUnits: Int64
        public let interestMinorUnits: Int64
        public let totalMinorUnits: Int64
        public let remainingPrincipalMinorUnits: Int64

        public var principalPercent: Double {
            guard totalMinorUnits > 0 else { return 0 }
            return Double(principalMinorUnits) / Double(totalMinorUnits) * 100
        }

        public var interestPercent: Double {
            guard totalMinorUnits > 0 else { return 0 }
            return Double(interestMinorUnits) / Double(totalMinorUnits) * 100
        }
    }

    /// Annual interest rate as decimal (e.g., 0.09 for 9% p.a.).
    public let annualRate: Double
    /// Remaining principal balance before this payment (in minor units, e.g., paise).
    public let principalMinorUnits: Int64
    /// EMI payment amount (in minor units).
    public let emiMinorUnits: Int64

    public init(annualRate: Double, principalMinorUnits: Int64, emiMinorUnits: Int64) {
        self.annualRate = annualRate
        self.principalMinorUnits = principalMinorUnits
        self.emiMinorUnits = emiMinorUnits
    }

    /// Calculates principal and interest split for a single EMI payment.
    public func amortize() -> AmortizedPayment {
        let monthlyRate = annualRate / 12
        let interestMinorUnits = Int64(Double(principalMinorUnits) * monthlyRate)
        let principalMinorUnits = emiMinorUnits - interestMinorUnits
        let remainingPrincipal = max(0, self.principalMinorUnits - principalMinorUnits)

        return AmortizedPayment(
            principalMinorUnits: max(0, principalMinorUnits),
            interestMinorUnits: interestMinorUnits,
            totalMinorUnits: emiMinorUnits,
            remainingPrincipalMinorUnits: remainingPrincipal
        )
    }
}
