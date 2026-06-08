import Charts
import FinanceCore
import FinanceUI
import SwiftUI

private struct ChartHoverState: Equatable {
    let hoveredDate: Date?
    let nearestNetWorthPoint: NetWorthPoint?

    static let idle = ChartHoverState()

    init(hoveredDate: Date? = nil, nearestNetWorthPoint: NetWorthPoint? = nil) {
        self.hoveredDate = hoveredDate
        self.nearestNetWorthPoint = nearestNetWorthPoint
    }
}

struct CombinedFinancialChartView: View {
    let netWorth: [NetWorthPoint]
    let visibleDays: Int?

    @State private var hoverState: ChartHoverState = .idle
    @State private var scrollPosition: Date

    init(netWorth: [NetWorthPoint], visibleDays: Int? = 90) {
        self.netWorth = netWorth
        self.visibleDays = visibleDays
        let days = visibleDays ?? 90
        _scrollPosition = State(
            initialValue: Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        )
    }

    var body: some View {
        Group {
            if let days = visibleDays {
                baseChart
                    .chartScrollableAxes(.horizontal)
                    .chartScrollPosition(x: $scrollPosition)
                    .chartXVisibleDomain(length: days * 24 * 3600)
            } else {
                baseChart
            }
        }
    }

    @AxisContentBuilder
    private var axisMarks: some AxisContent {
        switch visibleDays {
        case .none:
            AxisMarks(values: .stride(by: .year, count: 1)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(AppColors.border)
                AxisValueLabel(format: .dateTime.year()).foregroundStyle(AppColors.Text.tertiary)
            }
        case let .some(days) where days <= 90:
            AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(AppColors.border)
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    .foregroundStyle(AppColors.Text.tertiary)
            }
        case let .some(days) where days <= 180:
            AxisMarks(values: .stride(by: .month, count: 1)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(AppColors.border)
                AxisValueLabel(format: .dateTime.month(.abbreviated))
                    .foregroundStyle(AppColors.Text.tertiary)
            }
        default:
            AxisMarks(values: .stride(by: .month, count: 2)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(AppColors.border)
                AxisValueLabel(format: .dateTime.month(.abbreviated))
                    .foregroundStyle(AppColors.Text.tertiary)
            }
        }
    }

    private var baseChart: some View {
        StaticNetWorthChart(netWorth: netWorth)
            .chartYAxis(.hidden)
            .chartXAxis {
                axisMarks
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    let plotFrame = proxy.plotFrame.map { geo[$0] } ?? geo.frame(in: .local)
                    ZStack(alignment: .topLeading) {
                        if hoverState.hoveredDate != nil {
                            hoverOverlay(proxy: proxy, plotFrame: plotFrame)
                        }
                        Color.clear.contentShape(Rectangle())
                            .onContinuousHover { phase in
                                switch phase {
                                case let .active(loc):
                                    // Convert GeometryReader coords → plot area coords before querying proxy.
                                    let plotX = loc.x - plotFrame.origin.x
                                    if let date = proxy.value(atX: plotX, as: Date.self) {
                                        hoverState = buildHoverState(for: date)
                                    }
                                case .ended:
                                    hoverState = .idle
                                }
                            }
                    }
                }
            }
    }

    // MARK: - Hover Overlay

    @ViewBuilder
    private func hoverOverlay(proxy: ChartProxy, plotFrame: CGRect) -> some View {
        if let hoveredDate = hoverState.hoveredDate,
           let plotX = proxy.position(forX: hoveredDate) {
            // proxy.position(forX/Y:) returns plot-area-relative coords.
            // Add plotFrame.origin to get GeometryReader (overlay) coords.
            let xPos = plotX + plotFrame.origin.x

            Path { path in
                path.move(to: CGPoint(x: xPos, y: plotFrame.origin.y))
                path.addLine(to: CGPoint(x: xPos, y: plotFrame.maxY))
            }
            .stroke(AppColors.Text.quaternary.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            .allowsHitTesting(false)

            if let pt = hoverState.nearestNetWorthPoint,
               let plotY = proxy.position(forY: Double(pt.netWorthMinorUnits) / 100) {
                let yPos = plotY + plotFrame.origin.y
                Circle().fill(AppColors.accentBlue).stroke(AppColors.base, lineWidth: 2)
                    .frame(width: 8, height: 8).position(x: xPos, y: yPos).allowsHitTesting(false)
            }

            ChartHoverTooltip(state: hoverState)
                .offset(x: plotX > plotFrame.width * 0.6 ? xPos - 168 : xPos + 12, y: plotFrame.origin.y + 8)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Hover Logic

    private func buildHoverState(for date: Date) -> ChartHoverState {
        let nwPoint = nearestNetWorthPoint(to: date)
        return ChartHoverState(hoveredDate: nwPoint?.timestamp ?? date, nearestNetWorthPoint: nwPoint)
    }

    private func nearestNetWorthPoint(to date: Date) -> NetWorthPoint? {
        guard !netWorth.isEmpty else { return nil }
        var lo = 0, hi = netWorth.count - 1
        while lo < hi {
            let mid = (lo + hi) / 2
            if netWorth[mid].timestamp < date { lo = mid + 1 } else { hi = mid }
        }
        guard lo > 0 else { return netWorth[lo] }
        let d0 = abs(netWorth[lo - 1].timestamp.timeIntervalSince(date))
        let d1 = abs(netWorth[lo].timestamp.timeIntervalSince(date))
        return d0 <= d1 ? netWorth[lo - 1] : netWorth[lo]
    }
}

// MARK: - Chart

private struct StaticNetWorthChart: View {
    let netWorth: [NetWorthPoint]

    var body: some View {
        Chart {
            ForEach(netWorth) { item in
                let val = Double(item.netWorthMinorUnits) / 100
                AreaMark(x: .value("Date", item.timestamp), y: .value("Net Worth", val))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.accentBlue.opacity(0.20), .clear],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                LineMark(x: .value("Date", item.timestamp), y: .value("Net Worth", val))
                    .foregroundStyle(AppColors.accentBlue)
                    .lineStyle(StrokeStyle(lineWidth: 2.0))
                    .interpolationMethod(.catmullRom)
            }
        }
    }
}

// MARK: - Tooltip

private struct ChartHoverTooltip: View {
    let state: ChartHoverState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let date = state.hoveredDate {
                FDSLabel(FormatterCache.formatDate(date))
                    .font(AppTypography.captionSmSemibold)
                    .foregroundStyle(AppColors.Text.tertiary)
            }
            if let pt = state.nearestNetWorthPoint {
                let nwRupees = Decimal(pt.netWorthMinorUnits) / 100
                tooltipRow("Net Worth", value: fmt(nwRupees), color: AppColors.accentBlue)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppColors.surface2, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(AppColors.border, lineWidth: 0.5))
    }

    private func tooltipRow(_ label: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 6, height: 6)
            FDSLabel(label).font(AppTypography.captionSm).foregroundStyle(AppColors.Text.secondary)
            FDSLabel(value).font(AppTypography.captionSmSemibold)
                .foregroundStyle(AppColors.Text.primary).monospacedDigit()
        }
    }

    private func fmt(_ value: Decimal) -> String {
        FormatterCache.formatCurrency(value, currencyCode: "INR")
    }
}
