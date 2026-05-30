@testable import FinanceIntelligence
import Foundation
import Testing

private let resolver = PersonResolver()

// MARK: - UPI Person Transfers

@Test
func personResolver_upi_extractsNameAndHandle() {
    let result = resolver.resolve("UPI-RITIK GUPTA-ritikgupta@icici-HDFC-REF123456")
    #expect(result != nil)
    #expect(result?.name == "Ritik Gupta")
    #expect(result?.upiHandle == "ritikgupta@icici")
    #expect(result?.source == .upi)
    #expect(result?.confidence == 0.90)
}

@Test
func personResolver_upi_seemaGoel() {
    let result = resolver.resolve("UPI-SEEMA GOEL-seemagoel@sbi-SBI-TXN789")
    #expect(result?.name == "Seema Goel")
    #expect(result?.upiHandle == "seemagoel@sbi")
}

@Test
func personResolver_upi_amanPandey() {
    let result = resolver.resolve("UPI-AMAN PANDEY-aman@hdfc-AXIS-TXN456")
    #expect(result?.name == "Aman Pandey")
    #expect(result?.source == .upi)
}

@Test
func personResolver_upi_singleName() {
    let result = resolver.resolve("UPI-RAHUL-rahul123@kotak-ICICI-TXN111")
    #expect(result?.name == "Rahul")
}

@Test
func personResolver_upi_multiWordName() {
    let result = resolver.resolve("UPI-PRIYA SHARMA VERMA-priya@federal-HDFC-TXN222")
    #expect(result?.name == "Priya Sharma Verma")
}

@Test
func personResolver_upi_lowercaseHandle() {
    let result = resolver.resolve("UPI-JOHN DOE-johndoe@paytm-PAYTM-TXN333")
    // paytm VPA → business suffix → merchant, not person
    #expect(result == nil)
}

@Test
func personResolver_upi_withRefSuffix() {
    let result = resolver.resolve("UPI-VIKRAM NAIR-vikramnair@federal-FEDB-20260101")
    #expect(result?.name == "Vikram Nair")
}

@Test
func personResolver_upi_nameTitleCase() {
    let result = resolver.resolve("UPI-ANITA DESAI-anita@hdfc-HDFC-REF999")
    #expect(result?.name == "Anita Desai") // not "ANITA DESAI"
}

// MARK: - UPI Merchant Payments (must return nil)

@Test
func personResolver_upi_swiggyIsNotPerson() {
    let result = resolver.resolve("UPI-SWIGGY-swiggy@razorpay-AXIS-REF456")
    #expect(result == nil)
}

@Test
func personResolver_upi_amazonIsNotPerson() {
    let result = resolver.resolve("UPI-AMAZON-amazon@rzp-HDFC-REF789")
    #expect(result == nil)
}

@Test
func personResolver_upi_netflixIsNotPerson() {
    let result = resolver.resolve("UPI-NETFLIX-netflix@paytm-SBI-REF111")
    #expect(result == nil)
}

@Test
func personResolver_upi_zomatoIsNotPerson() {
    let result = resolver.resolve("UPI-ZOMATO-zomato@kotak-KOTAK-REF222")
    #expect(result == nil)
}

@Test
func personResolver_upi_blinkitIsNotPerson() {
    let result = resolver.resolve("UPI-BLINKIT-blinkit@ybl-YES-REF333")
    #expect(result == nil)
}

@Test
func personResolver_upi_pvtLtdIsNotPerson() {
    let result = resolver.resolve("UPI-ACME TECHNOLOGIES PVT LTD-acme@icici-ICIC-REF444")
    #expect(result == nil)
}

@Test
func personResolver_upi_marketplaceIsNotPerson() {
    let result = resolver.resolve("UPI-CF.ZEPTOMARKETPLACE-zepto@okicici-ICICI-REF555")
    #expect(result == nil)
}

@Test
func personResolver_upi_razorpayVpaIsNotPerson() {
    let result = resolver.resolve("UPI-MERCHANT NAME-merchant@razorpay-HDFC-REF666")
    #expect(result == nil)
}

@Test
func personResolver_upi_uberIsNotPerson() {
    let result = resolver.resolve("UPI-UBER-uber@apl-AXIS-REF777")
    #expect(result == nil)
}

@Test
func personResolver_upi_olaCabsIsNotPerson() {
    let result = resolver.resolve("UPI-OLA-ola@okaxis-AXIS-REF888")
    #expect(result == nil)
}

// MARK: - NEFT Transfers

@Test
func personResolver_neft_extractsPartyName() {
    let result = resolver.resolve("NEFT CR-HDFC0001234-SEEMA GOEL-NEFTREF789012")
    #expect(result != nil)
    #expect(result?.name == "Seema Goel")
    #expect(result?.upiHandle == nil)
    #expect(result?.source == .neft)
    #expect(result?.confidence == 0.80)
}

@Test
func personResolver_neft_debitTransfer() {
    let result = resolver.resolve("NEFT DR-ICIC0006789-RAJESH KUMAR-NEFTREF456")
    #expect(result?.name == "Rajesh Kumar")
    #expect(result?.source == .neft)
}

@Test
func personResolver_neft_multiWordName() {
    let result = resolver.resolve("NEFT CR-SBIN0001234-PRIYA SHARMA NAIR-REF001")
    #expect(result?.name == "Priya Sharma Nair")
}

@Test
func personResolver_neft_singleToken() {
    let result = resolver.resolve("NEFT CR-UTIB0000001-SURESH-REF002")
    #expect(result?.name == "Suresh")
}

@Test
func personResolver_neft_businessPartyIsNotPerson() {
    // "AMAZON INDIA PRIVATE" triggers business keyword → no result
    let result = resolver.resolve("NEFT CR-HDFC0000001-AMAZON INDIA PRIVATE-NEFTREF999")
    #expect(result == nil)
}

@Test
func personResolver_neft_technologyCompanyIsNotPerson() {
    let result = resolver.resolve("NEFT CR-ICIC0001234-XYZ TECHNOLOGIES LTD-REF555")
    #expect(result == nil)
}

@Test
func personResolver_neft_paymentServiceIsNotPerson() {
    let result = resolver.resolve("NEFT CR-YESB0000001-ABC PAYMENTS SERVICES-NEFTREF333")
    #expect(result == nil)
}

@Test
func personResolver_neft_zomatoIsNotPerson() {
    let result = resolver.resolve("NEFT CR-HDFC0001234-ZOMATO MEDIA-NEFTREF111")
    #expect(result == nil)
}

// MARK: - IMPS Transfers

@Test
func personResolver_imps_alwaysPersonTransfer() {
    let result = resolver.resolve("IMPS-123456789012-AMAN PANDEY-ICIC")
    #expect(result != nil)
    #expect(result?.name == "Aman Pandey")
    #expect(result?.source == .imps)
    #expect(result?.confidence == 0.75)
}

@Test
func personResolver_imps_shortName() {
    let result = resolver.resolve("IMPS-987654321098-RAVI-HDFC")
    #expect(result?.name == "Ravi")
}

@Test
func personResolver_imps_threePartName() {
    let result = resolver.resolve("IMPS-111222333444-NEHA SINHA ROY-SBIN")
    #expect(result?.name == "Neha Sinha Roy")
}

@Test
func personResolver_imps_noHandle() {
    let result = resolver.resolve("IMPS-555666777888-RAMESH PATEL-UTIB")
    #expect(result?.upiHandle == nil)
    #expect(result?.source == .imps)
}

@Test
func personResolver_imps_multiWordParty() {
    let result = resolver.resolve("IMPS-000111222333-DEEPAK SHARMA VERMA-KOTAK")
    #expect(result?.name == "Deepak Sharma Verma")
}

// MARK: - Edge Cases

@Test
func personResolver_nonStructured_returnsNil() {
    let result = resolver.resolve("SALARY CREDIT HDFC BANK JUNE 2026")
    #expect(result == nil) // not a UPI/NEFT/IMPS format
}

@Test
func personResolver_atmWithdrawal_returnsNil() {
    let result = resolver.resolve("ATM WITHDRAWAL HDFC BANK 12345")
    #expect(result == nil)
}

@Test
func personResolver_netflixCharge_returnsNil() {
    let result = resolver.resolve("NETFLIX SUBSCRIPTION MONTHLY")
    #expect(result == nil)
}

@Test
func personResolver_emptyDescription_returnsNil() {
    let result = resolver.resolve("")
    #expect(result == nil)
}

@Test
func personResolver_confidence_alwaysBounded() {
    let descriptions = [
        "UPI-PERSON NAME-person@upi-HDFC-REF",
        "NEFT CR-HDFC0001-PERSON NAME-REF",
        "IMPS-123456-PERSON NAME-ICIC"
    ]
    for desc in descriptions {
        guard let result = resolver.resolve(desc) else { continue }
        #expect(result.confidence >= 0.0)
        #expect(result.confidence <= 1.0)
    }
}

// MARK: - PersonEntityStore

@Test
func personEntityStore_deduplicatesBySameName() async {
    let store = PersonEntityStore()
    let date = Date()
    let p1 = await store.findOrCreate(name: "RITIK GUPTA", upiHandle: nil, date: date)
    let p2 = await store.findOrCreate(name: "RITIK GUPTA", upiHandle: nil, date: date)
    #expect(p1.id == p2.id)
    let count = await store.count
    #expect(count == 1)
}

@Test
func personEntityStore_deduplicatesByUPIHandle() async {
    let store = PersonEntityStore()
    let date = Date()
    let p1 = await store.findOrCreate(name: "RITIK", upiHandle: "ritik@upi", date: date)
    let p2 = await store.findOrCreate(name: "RITIK GUPTA", upiHandle: "ritik@upi", date: date)
    #expect(p1.id == p2.id)
}

@Test
func personEntityStore_incrementsTransactionCount() async {
    let store = PersonEntityStore()
    let date = Date()
    _ = await store.findOrCreate(name: "AMAN PANDEY", upiHandle: nil, date: date)
    let p = await store.findOrCreate(name: "AMAN PANDEY", upiHandle: nil, date: date)
    #expect(p.transactionCount == 2)
}

@Test
func personEntityStore_titleCasesCanonicalName() async {
    let store = PersonEntityStore()
    let p = await store.findOrCreate(name: "SEEMA GOEL", upiHandle: nil, date: Date())
    #expect(p.canonicalName == "Seema Goel")
}

@Test
func personEntityStore_stripsTitle() async {
    let store = PersonEntityStore()
    let p1 = await store.findOrCreate(name: "MR RITIK GUPTA", upiHandle: nil, date: Date())
    let p2 = await store.findOrCreate(name: "RITIK GUPTA", upiHandle: nil, date: Date())
    // Both "MR RITIK GUPTA" and "RITIK GUPTA" normalize to "RITIK GUPTA"
    #expect(p1.id == p2.id)
}

@Test
func personEntityStore_distinctNamesCreateDistinctPersons() async {
    let store = PersonEntityStore()
    let date = Date()
    _ = await store.findOrCreate(name: "RITIK GUPTA", upiHandle: nil, date: date)
    _ = await store.findOrCreate(name: "AMAN PANDEY", upiHandle: nil, date: date)
    let count = await store.count
    #expect(count == 2)
}
