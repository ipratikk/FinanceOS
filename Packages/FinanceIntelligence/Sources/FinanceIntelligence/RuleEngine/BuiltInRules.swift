// swiftlint:disable file_length
import Foundation

/// Default rule set shipped with the app.
/// Rules are evaluated in ascending priority order — lower integer = higher priority.
/// Add new rules by extending the appropriate section or adding a new section to `all`.
public enum BuiltInRules {
    /// Structural rule set — high-confidence deterministic rules only.
    /// Keyword-category rules (merchants, subscriptions, food, grocery, shopping, travel,
    /// healthcare, utilities) are intentionally absent: the trained PersonalizedClassifier
    /// handles those. Only keep rules for patterns that are format-determined, not name-determined.
    public static var all: [Rule] {
        incomeRules + creditCardRules + investmentRules + insuranceRules
            + withdrawalRules + housingRules + loanRules
            + transferRules + catchAllRules
    }
}

// MARK: - Income & Refunds (Priority 1–4)

extension BuiltInRules {
    static var incomeRules: [Rule] {
        [
            Rule(
                id: "income.salary",
                priority: 1,
                condition: .compound([.hasIndicator(.payroll), .isCredit]),
                outcome: RuleOutcome(
                    categoryId: "income",
                    subcategoryId: "income.salary",
                    intent: .salary,
                    confidence: 0.95
                )
            ),
            Rule(
                id: "income.salary.keywords",
                priority: 2,
                condition: .compound([
                    .tokenContainsAny(["salary", "payroll", "paycheck", "wages", "stipend"]),
                    .isCredit
                ]),
                outcome: RuleOutcome(
                    categoryId: "income",
                    subcategoryId: "income.salary",
                    intent: .salary,
                    confidence: 0.93
                )
            ),
            Rule(
                id: "income.refund",
                priority: 3,
                condition: .tokenContainsAny(["refund", "reversal", "chargeback", "upiret", "upi ret"]),
                outcome: RuleOutcome(
                    categoryId: "income",
                    subcategoryId: "income.refund",
                    intent: .refund,
                    confidence: 0.90
                )
            ),
            Rule(
                id: "income.dividend",
                priority: 3,
                condition: .compound([
                    .tokenContainsAny([
                        "dividend", "intdiv", "div2", "div1", "divid",
                        "motorsdiv", "palmolivind", "fnldiv", "tatadiv",
                        "interimdiv", "finaldiv", "bonusdiv"
                    ]),
                    .isCredit
                ]),
                outcome: RuleOutcome(
                    categoryId: "income",
                    subcategoryId: "income.dividend",
                    intent: .income,
                    confidence: 0.90
                )
            ),
            Rule(
                id: "income.interest",
                priority: 3,
                condition: .compound([
                    .tokenContainsAny(["interest paid", "int.pd", "interest credited", "savings interest"]),
                    .isCredit
                ]),
                outcome: RuleOutcome(
                    categoryId: "income",
                    subcategoryId: "income.interest",
                    intent: .income,
                    confidence: 0.90
                )
            ),
            Rule(
                id: "income.wire",
                priority: 3,
                condition: .compound([
                    .tokenContainsAny(["inw ", "inward remittance"]),
                    .isCredit
                ]),
                outcome: RuleOutcome(
                    categoryId: "income",
                    intent: .income,
                    confidence: 0.90
                )
            ),
            Rule(
                id: "income.cashback",
                priority: 4,
                condition: .tokenContainsAny(["cashback", "cash back", "reward credit", "reward points"]),
                outcome: RuleOutcome(
                    categoryId: "income",
                    subcategoryId: "income.refund",
                    intent: .cashback,
                    confidence: 0.88
                )
            )
        ]
    }
}

// MARK: - Credit Card Payments (Priority 5)

extension BuiltInRules {
    static var creditCardRules: [Rule] {
        [
            Rule(
                id: "payment.credit_card",
                priority: 5,
                condition: .tokenContainsAny([
                    "payment on cred", "cred ccbp",
                    "ib billpay", "billpay dr", "bill pay dr",
                    "credit card payment", "card payment"
                ]),
                outcome: RuleOutcome(categoryId: "fees", intent: .creditCardPayment, confidence: 0.92)
            )
        ]
    }
}

// MARK: - Investment & SIP (Priority 6)

extension BuiltInRules {
    static var investmentRules: [Rule] {
        [
            Rule(
                id: "investment.sip",
                priority: 6,
                condition: .tokenContainsAny([
                    "sip", "systematic investment", "nach debit", "mutual fund",
                    "indian clearing", "ach d", "nsdl clearing", "bse clearing"
                ]),
                outcome: RuleOutcome(
                    categoryId: "investments",
                    subcategoryId: "investments.sip",
                    intent: .mutualFundSIP,
                    confidence: 0.92
                )
            )
        ]
    }
}

// MARK: - Insurance (Priority 8)

extension BuiltInRules {
    static var insuranceRules: [Rule] {
        [
            Rule(
                id: "insurance.premium",
                priority: 8,
                condition: .tokenContainsAny(["insurance premium", "policy premium", "nach insurance"]),
                outcome: RuleOutcome(categoryId: "insurance", intent: .insurance, confidence: 0.92)
            )
        ]
    }
}

// MARK: - Subscriptions (Priority 9)

extension BuiltInRules {
    static var subscriptionRules: [Rule] {
        [
            Rule(
                id: "subscription.streaming",
                priority: 9,
                condition: .tokenContainsAny([
                    "netflix", "spotify", "amazon prime", "hotstar", "disney",
                    "jio cinema", "zee5", "sonyliv", "apple music", "apple tv",
                    "youtube premium", "linkedin premium", "adobe", "microsoft 365",
                    "office 365", "dropbox", "notion", "github"
                ]),
                outcome: RuleOutcome(categoryId: "subscriptions", intent: .subscription, confidence: 0.90)
            )
        ]
    }
}

// MARK: - Cash Withdrawal (Priority 10)

extension BuiltInRules {
    static var withdrawalRules: [Rule] {
        [
            Rule(
                id: "cash.atm",
                priority: 10,
                condition: .tokenContainsAny(["atm withdrawal", "cash withdrawal", "atm cash", "atw"]),
                outcome: RuleOutcome(categoryId: "atm", intent: .cashWithdrawal, confidence: 0.92)
            ),
            Rule(
                id: "fees.bank",
                priority: 10,
                condition: .tokenContainsAny([
                    "dcardfee", "ecsrtn", "ecs rtn", "mandate bounce", "return charge"
                ]),
                outcome: RuleOutcome(
                    categoryId: "fees",
                    subcategoryId: "fees.bank",
                    intent: .interestPayment,
                    confidence: 0.92
                )
            ),
            Rule(
                id: "taxes.gst",
                priority: 10,
                condition: .tokenContainsAny(["sgst", "cgst", "igst", "tds deducted", "tds on"]),
                outcome: RuleOutcome(categoryId: "taxes", intent: .unknown, confidence: 0.92)
            ),
            Rule(
                id: "transfer.upi_lite",
                priority: 11,
                condition: .tokenContainsAny(["upilite", "upi lite"]),
                outcome: RuleOutcome(categoryId: "transfers", intent: .transfer, confidence: 0.88)
            ),
            Rule(
                id: "transfer.internal_fund",
                priority: 11,
                condition: .tokenContainsAny(["bil/inft", "bilinft", "inft/", "internal fund"]),
                outcome: RuleOutcome(categoryId: "transfers", intent: .transfer, confidence: 0.88)
            ),
            Rule(
                id: "income.ach_credit",
                priority: 4,
                condition: .compound([
                    .tokenContainsAny(["ach/", "ach cr"]),
                    .isCredit
                ]),
                outcome: RuleOutcome(
                    categoryId: "income",
                    subcategoryId: "income.dividend",
                    intent: .income,
                    confidence: 0.82
                )
            )
        ]
    }
}

// MARK: - Housing / Rent (Priority 12)

extension BuiltInRules {
    static var housingRules: [Rule] {
        [
            Rule(
                id: "housing.rent",
                priority: 12,
                condition: .tokenContainsAny(["rent", "rental", "house rent", "flat rent", "pg rent", "nobroker"]),
                outcome: RuleOutcome(
                    categoryId: "housing",
                    subcategoryId: "housing.rent",
                    intent: .rent,
                    confidence: 0.88
                )
            )
        ]
    }
}

// MARK: - Loans & Interest (Priority 13–14)

extension BuiltInRules {
    static var loanRules: [Rule] {
        [
            Rule(
                id: "loan.emi",
                priority: 13,
                condition: .tokenContainsAny([
                    "loan emi", "emi payment", "home loan", "car loan", "personal loan",
                    "education loan", "bajaj finance", "hdfc loan", "icici loan",
                    "equated monthly"
                ]),
                outcome: RuleOutcome(categoryId: "fees", intent: .loanPayment, confidence: 0.90)
            ),
            Rule(
                id: "loan.interest",
                priority: 4,
                condition: .tokenContainsAny(
                    ["interest charge", "finance charge", "late payment fee", "penal interest"]
                ),
                outcome: RuleOutcome(
                    categoryId: "fees",
                    subcategoryId: "fees.interest",
                    intent: .interestPayment,
                    confidence: 0.88
                )
            )
        ]
    }
}

// MARK: - Transfers (Priority 15)

extension BuiltInRules {
    static var transferRules: [Rule] {
        [
            Rule(
                id: "transfer.generic",
                priority: 15,
                condition: .hasIndicator(.transfer),
                outcome: RuleOutcome(categoryId: "transfers", intent: .transfer, confidence: 0.92)
            )
        ]
    }
}

// MARK: - Utilities (Priority 20)

extension BuiltInRules {
    static var utilityRules: [Rule] {
        [
            Rule(
                id: "utilities.bill",
                priority: 20,
                condition: .tokenContainsAny([
                    "electricity", "bescom", "tpddl", "adani electricity", "bses",
                    "water bill", "piped gas", "mahanagar gas", "broadband", "internet bill",
                    "postpaid bill", "mobile bill", "airtel", "jio recharge", "bsnl",
                    "vi recharge", "tata sky", "dish tv", "dth recharge"
                ]),
                outcome: RuleOutcome(categoryId: "utilities", intent: .utilityBill, confidence: 0.88)
            )
        ]
    }
}

// MARK: - Food & Dining (Priority 22)

extension BuiltInRules {
    static var foodRules: [Rule] {
        [
            Rule(
                id: "food.delivery",
                priority: 22,
                condition: .tokenContainsAny([
                    "swiggy", "zomato", "restaurant", "cafe", "dhaba",
                    "dominos", "pizza hut", "mcdonalds", "kfc", "burger king",
                    "subway", "haldirams", "barbeque nation", "food delivery"
                ]),
                outcome: RuleOutcome(categoryId: "dining", intent: .food, confidence: 0.85)
            )
        ]
    }
}

// MARK: - Groceries (Priority 24)

extension BuiltInRules {
    static var groceryRules: [Rule] {
        [
            Rule(
                id: "groceries.supermarket",
                priority: 24,
                condition: .tokenContainsAny([
                    "bigbasket", "bbnow", "zepto", "blinkit", "grofers", "dunzo",
                    "dmart", "reliance fresh", "more supermarket",
                    "nature basket", "spencers", "supermarket", "grocery"
                ]),
                outcome: RuleOutcome(categoryId: "groceries", intent: .groceries, confidence: 0.87)
            )
        ]
    }
}

// MARK: - Shopping (Priority 26)

extension BuiltInRules {
    static var shoppingRules: [Rule] {
        [
            Rule(
                id: "shopping.ecommerce",
                priority: 26,
                condition: .tokenContainsAny([
                    "amazon", "amzn", "flipkart", "meesho", "myntra", "ajio",
                    "nykaa", "tata cliq", "snapdeal", "shopclues", "indiamart",
                    "h and m", "hennes", "ikea", "zara", "uniqlo",
                    "razorpay", "pay via razorpay", "razorpay.2",
                    "pinelabs", "pineaxis", "pine labs", "innovativeretail"
                ]),
                outcome: RuleOutcome(
                    categoryId: "shopping",
                    subcategoryId: "shopping.online",
                    intent: .shopping,
                    confidence: 0.82
                )
            )
        ]
    }
}

// MARK: - Travel & Transport (Priority 28)

extension BuiltInRules {
    static var travelRules: [Rule] {
        [
            Rule(
                id: "travel.transport",
                priority: 28,
                condition: .tokenContainsAny([
                    "uber", "ola", "rapido", "indrive", "irctc", "makemytrip",
                    "goibibo", "yatra", "cleartrip", "easemytrip", "indigo",
                    "spicejet", "air india", "vistara", "akasa", "airport",
                    "metro card", "dmrc", "bmtc"
                ]),
                outcome: RuleOutcome(categoryId: "transportation", intent: .travel, confidence: 0.85)
            )
        ]
    }
}

// MARK: - Healthcare (Priority 30)

extension BuiltInRules {
    static var healthcareRules: [Rule] {
        [
            Rule(
                id: "healthcare.medical",
                priority: 30,
                condition: .tokenContainsAny([
                    "hospital", "pharmacy", "medical", "doctor", "clinic",
                    "apollo", "fortis", "max hospital", "medplus", "netmeds",
                    "1mg", "pharmeasy", "tata 1mg", "dental", "optician"
                ]),
                outcome: RuleOutcome(categoryId: "healthcare", intent: .healthcare, confidence: 0.87)
            )
        ]
    }
}

// MARK: - Catch-All (Priority 40–50)

extension BuiltInRules {
    static var catchAllRules: [Rule] {
        [
            Rule(
                id: "catchall.credit",
                priority: 40,
                condition: .isCredit,
                outcome: RuleOutcome(categoryId: "income", intent: .income, confidence: 0.55)
            ),
            Rule(
                id: "catchall.unknown",
                priority: 50,
                condition: .anyOf([.isDebit, .isCredit]),
                outcome: RuleOutcome(categoryId: "uncategorized", intent: .unknown, confidence: 0.30)
            )
        ]
    }
}
