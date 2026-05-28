// FinanceIntelligence — Local-first transaction intelligence for FinanceOS.
//
// Data flow:
//   Transaction
//     → TransactionFeatureExtractor  → TransactionFeatures
//     → MerchantNormalizer           → MerchantCandidate
//     → RuleBasedCategorizer         → CategoryPrediction
//     → TransactionIntelligenceServiceImpl → AnalyzedTransaction
//
// Core ML model (when available) replaces RuleBasedCategorizer.
// User corrections always take highest priority over model output.
//
// App integration:
//   let service = await TransactionIntelligenceServiceImpl(configuration: .default)
//   let result = try await service.analyze(transaction, context: .empty)
