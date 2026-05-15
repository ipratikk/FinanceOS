import FinanceCore
import FinanceParsers
import SwiftUI
import UniformTypeIdentifiers

struct SourcePickerSection: View {
    @Binding var selectedSource: StatementSource?
    let errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            if let error = errorMessage {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Error")
                        .font(.caption)
                        .fontWeight(.semibold)

                    Text(error)
                        .font(.caption)
                        .lineLimit(5)
                }
                .foregroundColor(.red)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(4)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Statement Source")
                    .font(.headline)
                    .fontWeight(.semibold)

                Picker("Source", selection: $selectedSource) {
                    Text("Select source...").tag(StatementSource?.none)
                    ForEach(StatementSource.allCases, id: \.self) { source in
                        Text(source.displayName).tag(Optional(source))
                    }
                }
                .pickerStyle(.menu)

                if selectedSource == nil {
                    Text("Select a source to begin")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
    }
}

struct DropZoneView: View {
    let selectedSource: StatementSource?

    var body: some View {
        let formatNames = selectedSource?.allowedFormats.map { $0.rawValue.uppercased() }.joined(separator: ", ") ?? ""
        return VStack(spacing: 12) {
            Image(systemName: "arrow.down.doc.fill")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            VStack(spacing: 4) {
                Text("Drag files here or click button below")
                    .font(.headline)

                Text("Supported: \(formatNames)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }
}

struct FileSelectionPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.doc.fill")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("Select a source above to import files")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}
