#!/usr/bin/env swift
//
// Collect labeled dataset from real FeedbackStore events
// Usage: swift Scripts/collect_from_feedbackstore.swift [output_format]
// Output: CSV or JSON export of collected examples
//
// This tool:
// 1. Opens FinanceCore database
// 2. Queries FeedbackStore for merchant_corrected and category_corrected events
// 3. Runs DatasetCollector to build labeled examples
// 4. Exports as CSV/JSON
//

import Foundation

print("""
ML-001 Data Collection Tool
===========================

This script collects real-world labeled examples from FeedbackStore.

Requirements:
  - FinanceCore package with GRDB database
  - Active FeedbackStore events in database
  - Read access to intelligence_feedback_events table

Collect process:
  1. Query FeedbackStore events
  2. Infer labels from correction context
  3. Validate & deduplicate
  4. Export for training

To use this interactively:
  1. Start iOS app or create test database with feedback events
  2. Connect to database
  3. Export dataset

For now, this is a template showing the collection workflow.
Actual integration requires:
  - DatabaseQueue instance
  - FeedbackStore protocol implementation
  - Active test/production data

Example integration in AppContainer:

  let orchestrator = DatasetOrchestrator()
  await orchestrator.seedFromFixtures()

  // If database available:
  if let feedbackStore = appContainer.feedbackStore {
      try await orchestrator.collectFromFeedbackStore(feedbackStore)
  }

  let dataset = await orchestrator.buildDataset()
  let validator = DatasetValidator()
  let report = validator.validate(dataset)

  if report.isValid {
      let json = try await orchestrator.exportJSON()
      FileManager.default.createFile(atPath: "dataset.json", contents: json)
  }

Status: Template mode (ready for integration)
Next: Wire into app lifecycle for continuous collection
""")

// Log available paths
print("\nAvailable output formats:")
print("  csv  - Comma-separated values (for spreadsheet review)")
print("  json - JSON format (for programmatic import)")

let format = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "csv"
print("\nSelected format: \(format)")
print("\nNote: Actual data collection requires live FeedbackStore connection.")
