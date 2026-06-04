import FinanceIntelligence
import Foundation
import Observation

@Observable @MainActor
final class FeedbackExportViewModel {
    var correctionCount: Int = 0
    var lastExportDate: Date?
    var isExporting: Bool = false
    var exportError: String?
    var exportedFileURL: URL?

    private let exporter = FeedbackExporter()
    private let correctionStore: UserCorrectionStore
    private static let lastExportKey = "FeedbackExport.lastExportDate"

    init() {
        let storeURL = IntelligenceServiceConfiguration.default.correctionStoreURL
        correctionStore = UserCorrectionStore(storageURL: storeURL)
        if let stored = UserDefaults.standard.object(forKey: Self.lastExportKey) as? Date {
            lastExportDate = stored
        }
    }

    func load() async {
        let corrections = await correctionStore.exportTrainingEligible()
        correctionCount = corrections.count
    }

    var canExport: Bool {
        exporter.shouldExport(correctionCount: correctionCount, daysSinceLastExport: daysSinceLastExport)
    }

    var exportStatusText: String {
        guard let date = lastExportDate else { return "Never exported" }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        return days == 0 ? "Exported today" : "\(days) day\(days == 1 ? "" : "s") ago"
    }

    func exportFeedback() async {
        isExporting = true
        exportError = nil
        defer { isExporting = false }

        let corrections = await correctionStore.exportTrainingEligible()
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filename = "feedback_export_\(Date().ISO8601Format()).csv"
        let csvURL = docsURL.appendingPathComponent(filename)

        do {
            let url = try exporter.writeCSV(from: corrections, to: csvURL)
            exportedFileURL = url
            lastExportDate = Date()
            UserDefaults.standard.set(lastExportDate, forKey: Self.lastExportKey)
        } catch {
            exportError = error.localizedDescription
        }
    }

    private var daysSinceLastExport: Int {
        guard let date = lastExportDate else { return Int.max }
        return Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? Int.max
    }
}
