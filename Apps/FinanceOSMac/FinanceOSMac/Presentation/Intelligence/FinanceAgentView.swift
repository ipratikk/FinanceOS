import FinanceCore
import FinanceUI
import SwiftUI

struct FinanceAgentView: View {
    @State private var viewModel: FinanceAgentViewModel

    init(viewModel: FinanceAgentViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private let suggestedQueries: [String] = [
        "How much did I spend this month?",
        "Where do I spend the most?",
        "What are my recurring payments?",
        "Any unusual transactions?",
        "What's my net cashflow?"
    ]

    var body: some View {
        VStack(spacing: 0) {
            historyOrEmptyState
            if let error = viewModel.error {
                FDSBanner(error, style: .error)
                    .padding(.horizontal, AppSpacing.md)
            }
            Divider()
            inputBar
        }
        .background(AppColors.base)
        .navigationTitle("Finance Assistant")
        .task { await viewModel.loadTransactions() }
    }

    @ViewBuilder
    private var historyOrEmptyState: some View {
        if viewModel.history.isEmpty, !viewModel.isLoading {
            emptyState
        } else {
            historyList
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            Image(systemName: "sparkle.magnifyingglass")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(AppColors.accent)

            VStack(spacing: AppSpacing.compact) {
                FDSLabel("Ask anything about your finances")
                    .font(AppTypography.bodyMdSemibold)
                    .foregroundStyle(AppColors.Text.primary)
                FDSLabel("Try one of these to get started")
                    .font(AppTypography.bodySm)
                    .foregroundStyle(AppColors.Text.secondary)
            }

            VStack(spacing: AppSpacing.sm) {
                ForEach(suggestedQueries, id: \.self) { suggestion in
                    suggestionChip(suggestion)
                }
            }
            .padding(.horizontal, AppSpacing.xl)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func suggestionChip(_ text: String) -> some View {
        Button {
            Task { await viewModel.submitQuery(text) }
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "chevron.right")
                    .font(AppTypography.captionSmSemibold)
                    .foregroundStyle(AppColors.accent)
                FDSLabel(text)
                    .font(AppTypography.bodySmMedium)
                    .foregroundStyle(AppColors.Text.primary)
                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(AppColors.Glass.inputWell)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
        .buttonStyle(.plain)
    }

    private var historyList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: AppSpacing.md) {
                    ForEach(viewModel.history) { entry in
                        historyCard(entry)
                            .id(entry.id)
                    }
                    if viewModel.isLoading {
                        loadingRow
                    }
                }
                .padding(AppSpacing.md)
            }
            .onChange(of: viewModel.history.count) { _, _ in
                if let last = viewModel.history.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .onChange(of: viewModel.isLoading) { _, loading in
                if loading {
                    withAnimation { proxy.scrollTo("loading", anchor: .bottom) }
                }
            }
        }
    }

    private func historyCard(_ entry: FinanceAgentViewModel.QueryEntry) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "person.circle.fill")
                    .font(AppTypography.captionLg)
                    .foregroundStyle(AppColors.Text.secondary)
                FDSLabel(entry.query)
                    .font(AppTypography.bodySmMedium)
                    .foregroundStyle(AppColors.Text.primary)
                Spacer()
            }

            Divider().opacity(0.3)

            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(AppTypography.captionLg)
                    .foregroundStyle(AppColors.accent)
                VStack(alignment: .leading, spacing: AppSpacing.compact) {
                    toolBadge(entry.toolUsed)
                    FDSLabel(entry.answer)
                        .font(AppTypography.bodySm)
                        .foregroundStyle(AppColors.Text.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.Glass.inputWell)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    private func toolBadge(_ name: String) -> some View {
        FDSLabel(name)
            .font(AppTypography.captionSmMedium)
            .foregroundStyle(AppColors.accent)
            .padding(.horizontal, AppSpacing.compact)
            .padding(.vertical, 4)
            .background(AppColors.accent.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xs))
    }

    private var loadingRow: some View {
        HStack(spacing: AppSpacing.sm) {
            ProgressView()
                .controlSize(.small)
                .tint(AppColors.accent)
            FDSLabel("Thinking…")
                .font(AppTypography.bodySmMedium)
                .foregroundStyle(AppColors.Text.secondary)
        }
        .id("loading")
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
    }

    private var inputBar: some View {
        HStack(spacing: AppSpacing.sm) {
            TextField("Ask a financial question…", text: $viewModel.queryText)
                .textFieldStyle(.plain)
                .font(AppTypography.bodySmMedium)
                .foregroundStyle(AppColors.Text.primary)
                .onSubmit { Task { await viewModel.submit() } }

            Button {
                Task { await viewModel.submit() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        viewModel.queryText.trimmingCharacters(in: .whitespaces).isEmpty
                            ? AppColors.Text.tertiary
                            : AppColors.accent
                    )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.queryText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.Glass.inputWell)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .padding(AppSpacing.md)
    }
}
