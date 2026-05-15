import FinanceCore
import SwiftUI

struct DependencyInstallerView: View {
    @Binding var steps: [DependencyStep]
    var onDismiss: (() -> Void)?

    @State private var shouldDismiss = false
    private var allStepsDone: Bool {
        steps.allSatisfy { step in
            if case .running = step.status { return false }
            if case .pending = step.status { return false }
            return true
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Installing Dependencies")
                .font(.headline)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(steps) { step in
                        HStack(spacing: 12) {
                            stepIcon(for: step.status)
                                .font(.system(size: 18))
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.label)
                                    .font(.body)

                                if !step.logLines.isEmpty {
                                    VStack(alignment: .leading, spacing: 2) {
                                        ForEach(step.logLines, id: \.self) { line in
                                            Text(line)
                                                .font(.system(.caption, design: .monospaced))
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                            }

                            Spacer()
                        }
                        .opacity(opacity(for: step.status))
                    }
                }
                .padding()
            }

            HStack {
                Spacer()
                Button("Dismiss") {
                    shouldDismiss = true
                    onDismiss?()
                }
                .disabled(!allStepsDone)
            }
            .padding()
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
        .onChange(of: allStepsDone) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    shouldDismiss = true
                    onDismiss?()
                }
            }
        }
    }

    private func stepIcon(for status: StepStatus) -> Text {
        switch status {
        case .pending:
            return Text("◯")
        case .running:
            return Text("⟳")
        case .done:
            return Text("✓").foregroundColor(.green)
        case .failed:
            return Text("✗").foregroundColor(.red)
        }
    }

    private func opacity(for status: StepStatus) -> Double {
        if case .running = status { return 1.0 }
        if case .done = status { return 1.0 }
        if case .failed = status { return 1.0 }
        return 0.6
    }
}

#Preview {
    VStack {
        DependencyInstallerView(
            steps: .constant([
                DependencyStep(label: "Checking for ssconvert", status: .done),
                DependencyStep(label: "Checking for Homebrew", status: .done),
                DependencyStep(label: "Installing gnumeric", status: .running, logLines: ["==> Downloading gnumeric", "==> Installing gnumeric", "==> Pouring gnumeric--1.12.54.arm64_monterey.bottle.tar.gz"]),
                DependencyStep(label: "Verifying ssconvert", status: .pending)
            ])
        )
    }
}
