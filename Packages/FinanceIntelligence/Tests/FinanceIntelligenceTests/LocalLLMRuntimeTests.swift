@testable import FinanceIntelligence
import Foundation
import Testing

@Suite("LocalLLMRuntime — device gates + configuration")
struct LocalLLMRuntimeTests {
    @Test("Device capability reads physical RAM")
    func deviceCapabilityRAMReading() {
        let cap = LLMDeviceCapability.current()
        #expect(cap.physicalRAMBytes > 0)
    }

    @Test("Minimum RAM threshold is 6GB")
    func minimumRAMThreshold() {
        #expect(LLMDeviceCapability.minimumRAMBytes == 6 * 1024 * 1024 * 1024)
    }

    @Test("Incapable device has reason string")
    func incapableDeviceReason() {
        let ramBytes: UInt64 = 2 * 1024 * 1024 * 1024
        let cap = LLMDeviceCapability(physicalRAMBytes: ramBytes, isCapable: false, reason: "Too little RAM")
        #expect(cap.reason != nil)
        #expect(cap.isCapable == false)
    }

    @Test("Capable device has no reason string")
    func capableDeviceNoReason() {
        let cap = LLMDeviceCapability(physicalRAMBytes: 8 * 1024 * 1024 * 1024, isCapable: true, reason: nil)
        #expect(cap.reason == nil)
        #expect(cap.isCapable == true)
    }

    @Test("LocalLLMRuntime.make returns nil on low-RAM device")
    func runtimeNilOnLowRAM() {
        let cap = LLMDeviceCapability.current()
        if !cap.isCapable {
            #expect(LocalLLMRuntime.make() == nil)
        }
    }

    @Test("Phi3Mini config has correct context length")
    func phi3MiniConfig() {
        #expect(LLMModelConfig.phi3Mini.contextLength == 4096)
        #expect(LLMModelConfig.phi3Mini.quantization == "4bit")
    }

    @Test("Mistral7B config has correct context length")
    func mistral7BConfig() {
        #expect(LLMModelConfig.mistral7B.contextLength == 8192)
    }

    @Test("LLMGenerateParams concise preset has low max tokens")
    func concisePreset() {
        #expect(LLMGenerateParams.concise.maxTokens == 128)
        #expect(LLMGenerateParams.concise.temperature < 0.5)
    }

    @Test("LLMGenerateParams balanced preset")
    func balancedPreset() {
        #expect(LLMGenerateParams.balanced.maxTokens == 256)
    }
}
