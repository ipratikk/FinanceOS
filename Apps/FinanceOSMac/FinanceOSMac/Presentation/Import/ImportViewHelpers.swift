import FinanceCore
import FinanceParsers
import SwiftUI
import UniformTypeIdentifiers

struct SourcePickerSection: View {
    @Binding var selectedSource: StatementSource?
    let errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("1. Statement Source")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.gray)

                    Text("Select your bank")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(red: 0.447, green: 0.447, blue: 0.478))
                }

                Spacer()

                if selectedSource != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.231, green: 0.510, blue: 0.980))
                }
            }

            if let error = errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.red)

                        Text(error)
                            .font(.system(size: 12, weight: .regular))
                            .lineLimit(3)
                    }
                }
                .padding(10)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }

            Picker("Source", selection: $selectedSource) {
                Text("Select a bank...").tag(StatementSource?.none)
                ForEach(StatementSource.allCases, id: \.self) { source in
                    Text(source.displayName).tag(Optional(source))
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color(red: 0.110, green: 0.110, blue: 0.122))
            .cornerRadius(6)
        }
        .padding(12)
        .background(Color(red: 0.086, green: 0.086, blue: 0.098))
        .cornerRadius(10)
    }
}

struct DropZoneView: View {
    let selectedSource: StatementSource?
    @State private var isHovered = false

    var body: some View {
        let formatNames = selectedSource?.allowedFormats.map { $0.rawValue.uppercased() }
            .joined(separator: ", ") ?? ""

        return VStack(spacing: 12) {
            VStack(spacing: 12) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(Color(red: 0.231, green: 0.510, blue: 0.980))

                VStack(spacing: 4) {
                    Text("Drop files here")
                        .font(.system(size: 14, weight: .semibold))

                    Text("or click button below")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(red: 0.447, green: 0.447, blue: 0.478))

                    Text("Supported: \(formatNames)")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(red: 0.447, green: 0.447, blue: 0.478))
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(
                Color(red: 0.110, green: 0.110, blue: 0.122)
                    .opacity(isHovered ? 1 : 0.5)
            )
            .cornerRadius(10)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
        }
        .padding(12)
        .background(Color(red: 0.086, green: 0.086, blue: 0.098))
        .cornerRadius(10)
    }
}

struct FileSelectionPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.doc.fill")
                .font(.system(size: 40, weight: .semibold))
                .foregroundColor(Color(red: 0.447, green: 0.447, blue: 0.478))

            VStack(spacing: 4) {
                Text("Select a bank above")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.447, green: 0.447, blue: 0.478))

                Text("to start importing")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(red: 0.447, green: 0.447, blue: 0.478))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(Color(red: 0.086, green: 0.086, blue: 0.098))
        .cornerRadius(10)
    }
}
