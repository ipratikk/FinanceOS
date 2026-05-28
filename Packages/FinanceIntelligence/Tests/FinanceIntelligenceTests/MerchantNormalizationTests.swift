@testable import FinanceIntelligence
import Foundation
import Testing

// MARK: - MerchantTextCleaner

@Test
func cleaner_stripsSquarePOSPrefix() {
    let cleaner = MerchantTextCleaner()
    let result = cleaner.clean("SQ *BLUE BOTTLE 000123 SAN FRANCISCO CA")
    #expect(result.contains("BLUE BOTTLE"))
    #expect(!result.contains("SQ *"))
    #expect(!result.contains("000123"))
}

@Test
func cleaner_stripsUberURL() {
    let cleaner = MerchantTextCleaner()
    let result = cleaner.clean("UBER TRIP HELP.UBER.COM")
    #expect(result.contains("UBER TRIP"))
    #expect(!result.contains("HELP.UBER.COM"))
}

@Test
func cleaner_stripsAmazonMarketplaceId() {
    let cleaner = MerchantTextCleaner()
    let result = cleaner.clean("AMZN MKTP US*8A2K91")
    // Processor prefix is stripped; alphanumeric order IDs are resolved via alias lookup in MerchantNormalizer.
    #expect(!result.uppercased().contains("AMZN MKTP"))
}

@Test
func cleaner_stripsTstPrefix() {
    let cleaner = MerchantTextCleaner()
    let result = cleaner.clean("TST* SWEETGREEN #1042")
    #expect(result.contains("SWEETGREEN"))
    #expect(!result.contains("TST*"))
}

@Test
func cleaner_preservesMeaningfulText() {
    let cleaner = MerchantTextCleaner()
    let result = cleaner.clean("STARBUCKS STORE 12345 NEW YORK NY")
    #expect(result.contains("STARBUCKS"))
}

@Test
func cleaner_normalizedForMatchingIsLowercase() {
    let cleaner = MerchantTextCleaner()
    let result = cleaner.normalizedForMatching("STARBUCKS COFFEE")
    #expect(result == result.lowercased())
}

// MARK: - MerchantNormalizer

@Test
func normalizer_resolvesUberViaFuzzyMatch() {
    let normalizer = MerchantNormalizer()
    let result = normalizer.normalize("UBER TRIP HELP.UBER.COM")
    #expect(result.canonicalName == "Uber")
    #expect(result.confidence > 0.5)
}

@Test
func normalizer_resolvesAmazonViaFuzzyMatch() {
    let normalizer = MerchantNormalizer()
    let result = normalizer.normalize("AMZN Mktp US*8A2K91")
    #expect(result.canonicalName == "Amazon")
}

@Test
func normalizer_resolvesStarbucksViaFuzzyMatch() {
    let normalizer = MerchantNormalizer()
    let result = normalizer.normalize("STARBUCKS #12345 NEW YORK NY")
    #expect(result.canonicalName == "Starbucks")
}

@Test
func normalizer_fallsBackForUnknownMerchant() {
    let normalizer = MerchantNormalizer()
    let result = normalizer.normalize("QUIRKY LITTLE BISTRO BROOKLINE MA")
    #expect(!result.canonicalName.isEmpty)
    #expect(result.confidence <= 0.65)
}

@Test
func normalizer_rawDescriptionPreserved() {
    let normalizer = MerchantNormalizer()
    let raw = "TST* SWEETGREEN #1042 SAN FRANCISCO CA"
    let result = normalizer.normalize(raw)
    #expect(result.rawDescription == raw)
}

// MARK: - CategoryTaxonomy

@Test
func taxonomy_allCategoryIdsAreUnique() {
    let ids = CategoryTaxonomy.current.allCategoryIds
    let unique = Set(ids)
    #expect(ids.count == unique.count)
}

@Test
func taxonomy_containsRequiredTopLevelCategories() {
    let ids = Set(CategoryTaxonomy.current.allCategoryIds)
    let required = [
        "income",
        "transfers",
        "housing",
        "utilities",
        "groceries",
        "dining",
        "transportation",
        "healthcare",
        "subscriptions",
        "shopping",
        "uncategorized"
    ]
    for cat in required {
        #expect(ids.contains(cat), "Missing required category: \(cat)")
    }
}

@Test
func taxonomy_subcategoryIdsAreHierarchical() {
    for category in CategoryTaxonomy.current.categories {
        for sub in category.subcategories {
            #expect(sub.id.hasPrefix(category.id + "."), "Subcategory \(sub.id) not prefixed by \(category.id)")
        }
    }
}

@Test
func taxonomy_lookupByIdWorks() {
    #expect(CategoryTaxonomy.current.category(forId: "groceries") != nil)
    #expect(CategoryTaxonomy.current.subcategory(forId: "dining.coffee") != nil)
    #expect(CategoryTaxonomy.current.category(forId: "nonexistent") == nil)
}

@Test
func taxonomy_versionIsNonEmpty() {
    #expect(!CategoryTaxonomy.current.version.isEmpty)
}
