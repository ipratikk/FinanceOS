import Foundation

/// Download state for the NarrationEmbedder CoreML model.
public enum ModelDownloadState: Equatable, Sendable {
    case notDownloaded
    case downloading(progress: Double)
    case ready
    case failed(String)
}

/// Manages on-demand download of NarrationEmbedder v0.1 from GitHub Releases.
///
/// The 411 MB .mlmodelc.zip is downloaded to a temp location, unzipped into
/// Application Support/FinanceOS/Models/, and verified by checking the directory exists.
/// Callers observe `state` (published via AsyncStream) and call `download()` to start.
public actor ModelDownloadManager {
    public static let shared = ModelDownloadManager()

    private static let modelReleasePath =
        "https://github.com/ipratikk/FinanceOS/releases/download/" +
        "models-v0.1/NarrationEmbedder_v0.1.mlmodelc.zip"

    static var modelCacheDir: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("FinanceOS/Models", isDirectory: true)
    }

    static var compiledModelURL: URL {
        modelCacheDir.appendingPathComponent("NarrationEmbedder_v0.1.mlmodelc", isDirectory: true)
    }

    public private(set) var state: ModelDownloadState = .notDownloaded

    private var continuations: [UUID: AsyncStream<ModelDownloadState>.Continuation] = [:]

    public init() {
        let alreadyReady = FileManager.default.fileExists(atPath: Self.compiledModelURL.path)
        state = alreadyReady ? .ready : .notDownloaded
    }

    /// Whether the model is already cached and ready for inference.
    public var isReady: Bool {
        state == .ready
    }

    /// Subscribe to state changes.
    public func stateStream() -> AsyncStream<ModelDownloadState> {
        AsyncStream { continuation in
            let id = UUID()
            continuations[id] = continuation
            continuation.yield(state)
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeContinuation(id: id) }
            }
        }
    }

    /// Begin downloading the model. No-op if already ready or downloading. Retries from failed state.
    public func download() async {
        switch state {
        case .notDownloaded, .failed: break
        default: return
        }
        guard let downloadURL = URL(string: Self.modelReleasePath) else { return }

        do {
            try FileManager.default.createDirectory(at: Self.modelCacheDir, withIntermediateDirectories: true)
            setState(.downloading(progress: 0))

            let (zipURL, _) = try await URLSession.shared.download(from: downloadURL)
            setState(.downloading(progress: 0.9))

            try unzip(from: zipURL, to: Self.modelCacheDir)

            guard FileManager.default.fileExists(atPath: Self.compiledModelURL.path) else {
                setState(.failed("Model directory not found after unzip"))
                return
            }
            setState(.ready)
        } catch {
            setState(.failed(error.localizedDescription))
        }
    }

    /// Reset to notDownloaded (e.g. after clearing cache).
    public func reset() {
        try? FileManager.default.removeItem(at: Self.compiledModelURL)
        setState(.notDownloaded)
    }

    // MARK: - Private

    private func setState(_ newState: ModelDownloadState) {
        state = newState
        for continuation in continuations.values {
            continuation.yield(newState)
        }
    }

    private func removeContinuation(id: UUID) {
        continuations.removeValue(forKey: id)
    }

    private func unzip(from zipURL: URL, to destination: URL) throws {
        let archive = try ZIPArchive(url: zipURL)
        try archive.extract(to: destination)
    }
}

// MARK: - ZIPArchive (thin wrapper over ZIPFoundation)

private struct ZIPArchive {
    private let url: URL
    init(url: URL) throws {
        self.url = url
    }

    func extract(to destination: URL) throws {
        // Use Process on macOS for reliability; falls back to Foundation on iOS
        #if os(macOS)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", url.path, "-d", destination.path]
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            throw CocoaError(.fileWriteUnknown)
        }
        #else
        try FileManager.default.unzipItem(at: url, to: destination)
        #endif
    }
}
