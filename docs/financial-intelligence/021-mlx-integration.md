---
doc: 021-mlx-integration
version: 0.1.0
status: Draft
date: 2026-06-02
---

# MLX Integration — FinanceIntelligence Platform

## Purpose

Define the complete MLX Swift integration for on-device LLM inference. MLX is Apple's ML framework optimized for Apple Silicon, enabling efficient transformer inference on iPhone and Mac. This document covers: the Swift package dependency, `MLXLLMProvider` implementation, model management, memory budget, device capability gating, and the streaming inference interface used by description generation, insight generation, and the FinanceAgent.

---

## Why MLX

| Framework | On-Device | Apple Silicon | Streaming | Swift Native |
|---|---|---|---|---|
| CoreML | ✅ | ✅ | ❌ | ✅ |
| ONNX Runtime | ✅ | ⚠️ (no ANE) | ❌ | ❌ |
| MLX | ✅ | ✅ (unified memory) | ✅ | ✅ |
| llama.cpp | ✅ | ⚠️ (Metal backend) | ✅ | ❌ (C++) |

MLX is the preferred runtime for transformer models because:
1. Unified memory architecture — no CPU↔GPU copy overhead on Apple Silicon
2. Streaming token generation via `AsyncStream`
3. First-class Swift APIs (`mlx-swift`, `mlx-swift-examples`)
4. Active development by Apple (not a third party)

**CoreML is preferred for classification models (Models 1–6, 9)**  
**MLX is used only for generative models (Models 7 partial, 8, 10, 11) and the agent**

---

## Swift Package Dependency

```swift
// Packages/FinanceIntelligence/Package.swift

dependencies: [
    .package(url: "https://github.com/ml-explore/mlx-swift.git",
             from: "0.10.0"),
    .package(url: "https://github.com/ml-explore/mlx-swift-examples.git",
             from: "0.1.0"),
],

targets: [
    .target(
        name: "FinanceIntelligence",
        dependencies: [
            .product(name: "MLX", package: "mlx-swift"),
            .product(name: "MLXLLM", package: "mlx-swift-examples"),
            .product(name: "MLXRandom", package: "mlx-swift"),
        ]
    )
]
```

---

## LLMProvider Protocol

```swift
// Protocols/LLMProvider.swift

public protocol LLMProvider: Sendable {
    var modelName: String { get }
    var isAvailable: Bool { get }

    func complete(
        _ prompt: String,
        options: LLMOptions
    ) async throws -> String

    func stream(
        _ prompt: String,
        options: LLMOptions
    ) -> AsyncThrowingStream<String, Error>

    func completeWithTools(
        messages: [LLMMessage],
        tools: [LLMTool],
        options: LLMOptions
    ) async throws -> LLMToolCallResult
}

public struct LLMOptions: Sendable {
    public var maxNewTokens: Int = 256
    public var temperature: Float = 0.7
    public var topP: Float = 0.9
    public var repetitionPenalty: Float = 1.1
    public var stopSequences: [String] = ["\n\n"]
    public var seed: UInt64? = nil
}
```

---

## MLXLLMProvider Implementation

```swift
// LocalLLM/MLXLLMProvider.swift

import MLX
import MLXLLM

public final class MLXLLMProvider: LLMProvider {
    private let modelManager: ModelManager
    private var loadedModel: LLMModel?
    private var tokenizer: Tokenizer?
    private let modelName: String

    public init(modelManager: ModelManager, modelName: String) {
        self.modelManager = modelManager
        self.modelName = modelName
    }

    public var isAvailable: Bool {
        DeviceCapabilityChecker.supportsLLM() && modelManager.isDownloaded(modelName)
    }

    public func complete(_ prompt: String, options: LLMOptions) async throws -> String {
        try await ensureLoaded()
        guard let model = loadedModel, let tokenizer = tokenizer else {
            throw LLMError.modelNotLoaded
        }

        let tokens = tokenizer.encode(prompt)
        var output = ""
        var count = 0

        for await token in model.generate(tokens: tokens, parameters: options.toMLXParameters()) {
            let decoded = tokenizer.decode([token])
            output += decoded
            count += 1

            if count >= options.maxNewTokens { break }
            if options.stopSequences.contains(where: { output.hasSuffix($0) }) { break }
        }

        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func stream(_ prompt: String, options: LLMOptions) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    try await ensureLoaded()
                    guard let model = loadedModel, let tokenizer = tokenizer else {
                        throw LLMError.modelNotLoaded
                    }

                    let tokens = tokenizer.encode(prompt)
                    var count = 0

                    for await token in model.generate(tokens: tokens,
                                                      parameters: options.toMLXParameters()) {
                        let decoded = tokenizer.decode([token])
                        continuation.yield(decoded)
                        count += 1
                        if count >= options.maxNewTokens { break }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func ensureLoaded() async throws {
        guard loadedModel == nil else { return }
        let (model, tokenizer) = try await modelManager.load(modelName)
        self.loadedModel = model
        self.tokenizer = tokenizer
    }
}
```

---

## ModelManager

```swift
// LocalLLM/ModelManager.swift

public actor ModelManager {
    private let registry: any ModelRegistry
    private var loadedModels: [String: (LLMModel, Tokenizer)] = [:]

    public func load(_ name: String) async throws -> (LLMModel, Tokenizer) {
        if let cached = loadedModels[name] { return cached }

        let path = try registry.mlxArtifactPath(for: ModelName(name))
        let model = try await LLMModel.load(from: path)
        let tokenizer = try Tokenizer.load(from: path)
        loadedModels[name] = (model, tokenizer)
        return (model, tokenizer)
    }

    public func unload(_ name: String) {
        loadedModels.removeValue(forKey: name)
        MLX.GPU.clearCache()
    }

    public func unloadAll() {
        loadedModels.removeAll()
        MLX.GPU.clearCache()
    }

    public func isDownloaded(_ name: String) -> Bool {
        guard let path = try? registry.mlxArtifactPath(for: ModelName(name)) else { return false }
        return FileManager.default.fileExists(atPath: path.path)
    }
}
```

---

## Device Capability Gating

MLX LLMs require sufficient device capability. Gate at runtime:

```swift
// LocalLLM/DeviceCapabilityChecker.swift

public enum DeviceCapabilityChecker {
    public static func supportsLLM() -> Bool {
        // Minimum: 6 GB unified memory (iPhone 15 Pro, M1 and later)
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        let minimumBytes: UInt64 = 6 * 1024 * 1024 * 1024  // 6 GB
        return physicalMemory >= minimumBytes
    }

    public static func supportsLargeModel() -> Bool {
        // Large models (8B): require 8 GB+
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        let minimumBytes: UInt64 = 8 * 1024 * 1024 * 1024
        return physicalMemory >= minimumBytes
    }

    public static func thermalStateAllowsInference() -> Bool {
        ProcessInfo.processInfo.thermalState < .serious
    }

    public static func batteryAllowsInference() -> Bool {
        #if os(iOS)
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        let state = UIDevice.current.batteryState
        // Allow on charger regardless; allow on battery if > 20%
        return state == .charging || state == .full || level > 0.20
        #else
        return true  // macOS — always allow
        #endif
    }
}
```

---

## Memory Management

MLX uses unified memory (CPU/GPU shared). Memory pressure can cause thermal throttling or termination.

```swift
// LocalLLM/QuantizationManager.swift

public enum QuantizationLevel: String {
    case full      // float16 — highest quality, 2x memory
    case q8        // 8-bit — good quality, 1x memory
    case q4        // 4-bit — acceptable quality, 0.5x memory
    case q3        // 3-bit — reduced quality, 0.38x memory (emergency only)
}

// Model size budget per device class:
// iPhone 15 Pro (8 GB): q4 for 4B models, q4 for 8B Mac only
// M1 MacBook (8 GB): q4 for 4B, q8 for 4B if 16 GB+
// M2+ MacBook (16 GB): q4 for 8B, q8 for 4B
```

Register for memory pressure notifications:

```swift
NotificationCenter.default.addObserver(
    forName: UIApplication.didReceiveMemoryWarningNotification,
    object: nil, queue: .main
) { _ in
    Task { await modelManager.unloadAll() }
}
```

---

## ConversationMemory

```swift
// LocalLLM/ConversationMemory.swift

public actor ConversationMemory {
    private var messages: [LLMMessage] = []
    private let maxTokenBudget: Int

    public func append(_ message: LLMMessage) {
        messages.append(message)
        trimToTokenBudget()
    }

    private func trimToTokenBudget() {
        // Keep system prompt + last N messages within token budget
        // Trim oldest user/assistant turns first
        while estimatedTokenCount() > maxTokenBudget && messages.count > 2 {
            messages.remove(at: 1)  // preserve system prompt at index 0
        }
    }
}
```

---

## ContextManager

```swift
// LocalLLM/ContextManager.swift

public final class ContextManager {
    public func buildContext(for request: AgentRequest, financialData: FinancialContext) -> String {
        """
        [SYSTEM]
        You are FinanceOS Assistant, a personal finance AI. You have access to the user's
        transaction data through tools. You must use tools to access data — never make up
        financial figures. Today is \(Date.formatted(.iso8601)).
        
        [USER CONTEXT]
        Accounts: \(financialData.accountSummary)
        Last import: \(financialData.lastImportDate?.formatted() ?? "Never")
        
        [CONVERSATION]
        \(request.history.formatted())
        
        [USER]
        \(request.query)
        """
    }
}
```

---

## Performance Budget

| Model | Device | Quantization | Load Time | Token/sec | Memory |
|---|---|---|---|---|---|
| Phi-3 Mini 3.8B | iPhone 15 Pro | q4 | < 3 s | 20–30 t/s | ~2.2 GB |
| Qwen3 4B | iPhone 15 Pro | q4 | < 4 s | 15–25 t/s | ~2.5 GB |
| Qwen3 4B | M2 MacBook | q4 | < 2 s | 40–60 t/s | ~2.5 GB |
| Qwen3 8B | M2 MacBook | q4 | < 4 s | 25–40 t/s | ~4.8 GB |

---

## Risks

| Risk | Mitigation |
|---|---|
| mlx-swift API changes between versions | Pin exact version in Package.swift; test on package upgrade |
| LLM load time blocks UI thread | Load in background Task; show loading state in UI |
| Unified memory pressure causes iOS process termination | Memory warning handler unloads model immediately |
| MLX model files too large for App Store bundle | Ship model stubs; download models on first use from CDN (future work) |
| MLX not available on A15 Bionic or earlier | DeviceCapabilityChecker gates on physical memory, not chip model |
