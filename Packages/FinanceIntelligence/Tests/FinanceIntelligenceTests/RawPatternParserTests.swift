@testable import FinanceIntelligence
import Foundation
import Testing

@Suite("RawPatternParser — structured bank format parsing")
struct RawPatternParserTests {
    private let parser = RawPatternParser()

    // MARK: - INW inward remittance

    @Test("INW USD parses amount and rate")
    func inwUSD() {
        let result = parser.parse("INW 050526I049903643 USD2382.62@95.2648", merchantName: "")
        #expect(result == "Inward Remittance · $2,382.62 @ ₹95.26")
    }

    @Test("INW round amount formats correctly")
    func inwRoundAmount() {
        let result = parser.parse("INW 280725I049902285 USD2652.0@86.45", merchantName: "")
        #expect(result == "Inward Remittance · $2,652.00 @ ₹86.45")
    }

    @Test("INW EUR uses euro symbol")
    func inwEUR() {
        let result = parser.parse("INW TESTREF EUR1000.00@90.00", merchantName: "")
        #expect(result == "Inward Remittance · €1,000.00 @ ₹90.00")
    }

    @Test("INW GBP uses pound symbol")
    func inwGBP() {
        let result = parser.parse("INW TESTREF GBP500.00@105.00", merchantName: "")
        #expect(result == "Inward Remittance · £500.00 @ ₹105.00")
    }

    @Test("INW SGD uses S$ symbol from shared CurrencySymbol")
    func inwSGD() {
        let result = parser.parse("INW TESTREF SGD1000.00@75.00", merchantName: "")
        #expect(result == "Inward Remittance · S$1,000.00 @ ₹75.00")
    }

    @Test("INW unrecognised currency falls back to the raw code")
    func inwUnknownCurrency() {
        let result = parser.parse("INW TESTREF XAU1000.00@75.00", merchantName: "")
        #expect(result?.hasPrefix("Inward Remittance · XAU") == true)
    }

    @Test("Non-INW returns nil")
    func nonINWReturnsNil() {
        #expect(parser.parse("NEFT CR-BOFA0CN6215-PAYPAL INDIA", merchantName: "") == nil)
    }

    // MARK: - DPO tax charges

    @Test("DPO IGST on wire transfer")
    func dpoIGST() {
        let result = parser.parse("050526I049903643 DPO2712595243131 IGST", merchantName: "")
        #expect(result == "IGST on Wire Transfer")
    }

    @Test("DPO CGST on wire transfer")
    func dpoCGST() {
        let result = parser.parse("170525I049902001 DPO2613776482583 CGST", merchantName: "")
        #expect(result == "CGST on Wire Transfer")
    }

    @Test("DPO SGST on wire transfer")
    func dpoSGST() {
        let result = parser.parse("280725I049902285 DPO2620960417108 SGST", merchantName: "")
        #expect(result == "SGST on Wire Transfer")
    }

    @Test("String without DPO returns nil")
    func noDPOReturnsNil() {
        #expect(parser.parse("SOME RANDOM IGST STRING", merchantName: "") == nil)
    }

    // MARK: - IGST-VPS bank charges

    @Test("IGST-VPS with integer rate")
    func igstVPSIntegerRate() {
        let result = parser.parse(
            "IGST-VPS2710640872446- RATE 18.0 -29 (Ref# MT261060076000010015325)",
            merchantName: ""
        )
        #expect(result == "IGST · 18% on Bank Charges")
    }

    @Test("CGST-VPS with decimal rate")
    func cgstVPSDecimalRate() {
        let result = parser.parse(
            "CGST-VPS2710640872446- RATE 9.5 -29 (Ref# MT261060076000010015325)",
            merchantName: ""
        )
        #expect(result == "CGST · 9.5% on Bank Charges")
    }

    @Test("IGST-VPS without RATE still returns label")
    func igstVPSNoRate() {
        let result = parser.parse("IGST-VPS2710640872446-SOMETEXT", merchantName: "")
        #expect(result == "IGST on Bank Charges")
    }

    // MARK: - GST slash + bank charges

    @Test("GST/IGST@18% slash form")
    func gstSlashIGST() {
        #expect(parser.parse("GST/IGST@18%", merchantName: "") == "IGST · 18% on Bank Charges")
    }

    @Test("GST/CGST@9% slash form")
    func gstSlashCGST() {
        #expect(parser.parse("GST/CGST@9%", merchantName: "") == "CGST · 9% on Bank Charges")
    }

    @Test("Int.Pd interest range → Bank Interest")
    func intPdRange() {
        #expect(parser.parse("128301504472:Int.Pd:29-03-2025 to 29-06-2025", merchantName: "") == "Bank Interest")
    }

    @Test("SMS charges + GST → SMS Charges")
    func smsCharges() {
        #expect(parser.parse("SMSChgsApr25-Jun25+GST", merchantName: "") == "SMS Charges")
    }

    @Test("Debit card fee + GST → Debit Card Fee")
    func debitCardFee() {
        #expect(parser.parse("DCARDFEE2193MAY25-APR26+GST", merchantName: "") == "Debit Card Fee")
    }

    // MARK: - Interest

    @Test("Interest credit JUN")
    func interestJun() {
        let result = parser.parse("INTEREST PAID TILL 30-JUN-2025", merchantName: "")
        #expect(result == "Bank Interest · June 2025")
    }

    @Test("Interest credit MAR")
    func interestMar() {
        let result = parser.parse("INTEREST PAID TILL 31-MAR-2026", merchantName: "")
        #expect(result == "Bank Interest · March 2026")
    }

    @Test("Interest credit DEC")
    func interestDec() {
        let result = parser.parse("INTEREST PAID TILL 31-DEC-2025", merchantName: "")
        #expect(result == "Bank Interest · December 2025")
    }

    // MARK: - NEFT salary

    @Test("NEFT salary April 2025")
    func neftSalaryApril() {
        let raw = "NEFT CR-BOFA0CN6215-PAYPAL INDIA PVT LTD-PRATIK GOEL"
            + "-BOFAN52025042504212670 SALARY FOR APRIL 2025"
        let result = parser.parse(raw, merchantName: "PayPal India")
        #expect(result == "Salary from PayPal India · April 2025")
    }

    @Test("NEFT salary abbreviated month")
    func neftSalaryAbbreviatedMonth() {
        let raw = "NEFT CR-BOFA0CN6215-PAYPAL INDIA PVT LTD-PRATIK GOEL-BOFAH25329031741 SALARY FOR NOV 25"
        let result = parser.parse(raw, merchantName: "PayPal India")
        #expect(result == "Salary from PayPal India · Nov 25")
    }

    @Test("NEFT salary empty merchant")
    func neftSalaryNoMerchant() {
        let raw = "NEFT CR-BOFA0CN6215-PAYPAL INDIA PVT LTD-PRATIK GOEL SALARY FOR MAY 2025"
        let result = parser.parse(raw, merchantName: "")
        #expect(result == "Salary · May 2025")
    }

    @Test("NEFT debit does not match salary pattern (matches rent instead)")
    func neftDebitNotSalary() {
        let raw = "NEFT DR-ICIC0001283-SEEMA GOEL-NETBANK,MUM-HDFCN52025103063065156-HOUSE RENT"
        let result = parser.parse(raw, merchantName: "Seema Goel")
        #expect(result == "House Rent · Seema Goel")
        #expect(result?.lowercased().contains("salary") != true)
    }

    // MARK: - Rent

    @Test("NEFT HOUSE RENT debit produces rent label")
    func neftHouseRent() {
        let raw = "NEFT DR-ICIC0001283-SEEMA GOEL-NETBANK,MUM-HDFCN52025103063065156-HOUSE RENT"
        #expect(parser.parse(raw, merchantName: "Seema Goel") == "House Rent · Seema Goel")
    }

    @Test("UPI trailing RENT remark produces rent label")
    func upiTrailingRent() {
        let raw = "UPI-RITIK GUPTA-RITIKGUPTA0912@IBL-ICIC0000319-120551629458-RENT MARCH"
        #expect(parser.parse(raw, merchantName: "Ritik Gupta") == "House Rent · Ritik Gupta")
    }

    @Test("Exact RENT remark produces rent label")
    func exactRentRemark() {
        let raw = "UPI-RITIK GUPTA-RITIKGUPTA0912@IBL-ICIC0000319-111750501919-RENT"
        #expect(parser.parse(raw, merchantName: "Ritik Gupta") == "House Rent · Ritik Gupta")
    }

    @Test("RENTAL does not false-match as rent")
    func rentalNotRent() {
        let raw = "UPI-AVIS CAR RENTAL-AVIS@HDFC-HDFC0000001-123456789012-CAR RENTAL"
        #expect(parser.parse(raw, merchantName: "Avis Car Rental") == nil)
    }

    @Test("Rent with empty merchant returns bare label")
    func rentEmptyMerchant() {
        #expect(parser.parse("NEFT DR-X-Y-HOUSE RENT", merchantName: "") == "House Rent")
    }

    // MARK: - Nil for unrecognised

    @Test("UPI personal transfer returns nil")
    func upiPersonalNil() {
        let raw = "UPI-RITIK GUPTA-RITIKGUPTA0912@IBL-ICIC0000319-103744680442-UPI"
        #expect(parser.parse(raw, merchantName: "Ritik Gupta") == nil)
    }

    @Test("ACH SIP returns nil")
    func achSIPNil() {
        #expect(parser.parse("ACH D- INDIAN CLEARING CORP-0000KMZ6WD9G", merchantName: "ICCL") == nil)
    }

    @Test("Empty string returns nil")
    func emptyReturnsNil() {
        #expect(parser.parse("", merchantName: "") == nil)
    }
}
