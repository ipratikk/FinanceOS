/// FinanceIntelligence — Local-first, on-device transaction intelligence for FinanceOS.
///
/// Data flow:
/// ```
/// Transaction
///   → TransactionFeatureExtractor  → TransactionFeatures
///   → MerchantNormalizer           → MerchantCandidate
///   → TransactionIntelligenceServiceImpl → AnalyzedTransaction
/// ```
/// The CoreML model replaces `RuleBasedCategorizer` when available.
/// User corrections always take the highest priority over any model output.
///
/// App integration:
/// ```swift
/// let service = await TransactionIntelligenceServiceImpl(configuration: .default)
/// let result = try await service.analyze(transaction, context: .empty)
/// ```
