import Charts
import FinanceCore
import FinanceUI
import SwiftUI

// MARK: - Palette

private enum ChartPalette {
    /// Fixed palette drawn from AppColors.System for per-account lines.
    static let accountColors: [Color] = [
        AppColors.System.green,
        AppColors.System.orange,
        AppColors.System.purple,
        AppColors.System.pink,
        AppColors.System.teal,
        AppColors.System.yellow,
        AppColors.System.mint,
        AppColors.System.cyan,
        AppColors.System.indigo,
        AppColors.System.red
    ]

    static func color(for index: Int) -> Color {
        accountColors[index % accountColors.count]
    }
}

// MARK: - Series Model

private struct ChartSeries: Identifiable {
    let id: UUID
    let label: String
    let color: Color
    let lineWidth: CGFloat
    let isDashed: Bool
    let points: [NetWorthPoint]

    init(
        id: UUID = UUID(),
        label: String,
        color: Color,
        lineWidth: CGFloat = 2,
        isDashed: Bool = false,
        points: [NetWorthPoint]
    ) {
        self.id = id
        self.label = label
        self.color = color
        self.lineWidth = lineWidth
        self.isDashed = isDashed
        self.points = points
    }

    func nearestPoint(to date: Date) -> NetWorthPoint? {
        guard !points.isEmpty else { return nil }
        var low = 0, high = points.count - 1
        while low < high {
            let mid = (low + high) / 2
            if points[mid].timestamp < date { low = mid + 1 } else { high = mid }
        }
        guard low > 0 else { return points[low] }
        let distPrev = abs(points[low - 1].timestamp.timeIntervalSince(date))
        let distCurr = abs(points[low].timestamp.timeIntervalSince(date))
        return distPrev <= distCurr ? points[low - 1] : points[low]
    }
}

// MARK: - Hover State

private struct ChartHoverState: Equatable {
    /// The snapped date shown by the crosshair.
    let hoveredDate: Date?
    /// Nearest value per series, keyed by series ID.
    let seriesValues: [UUID: NetWorthPoint]

    static let idle = ChartHoverState()

    init(hoveredDate: Date? = nil, seriesValues: [UUID: NetWorthPoint] = [:]) {
        self.hoveredDate = hoveredDate
        self.seriesValues = seriesValues
    }

    static func == (lhs: ChartHoverState, rhs: ChartHoverState) -> Bool {
        lhs.hoveredDate == rhs.hoveredDate
    }
}

// MARK: - Main View

struct CombinedFinancialChartView: View {
    let netWorth: [NetWorthPoint]
    let bankAccountBalances: [LedgerBalanceTimeSeries]
    let visibleDays: Int?

    @State private var hoverState: ChartHoverState = .idle
    @State private var scrollPosition: Date

    init(
        netWorth: [NetWorthPoint],
        bankAccountBalances: [LedgerBalanceTimeSeries] = [],
        visibleDays: Int? = 90
    ) {
        self.netWorth = netWorth
        self.bankAccountBalances = bankAccountBalances
        self.visibleDays = visibleDays
        let days = visibleDays ?? 90
        _scrollPosition = State(
            initialValue: Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        )
    }

    private var allSeries: [ChartSeries] {
        var result: [ChartSeries] = []
        // Per-ledger lines first so total renders on top.
        for (idx, ledger) in bankAccountBalances.enumerated() {
            result.append(ChartSeries(
                id: ledger.ledgerId,
                label: ledger.ledgerName,
                color: ChartPalette.color(for: idx),
                lineWidth: 1.5,
                isDashed: false,
                points: ledger.points
            ))
        }
        // Total net worth: blue, thicker, dashed.
        result.append(ChartSeries(
            label: "Net Worth",
            color: AppColors.accentBlue,
            lineWidth: 2.5,
            isDashed: true,
            points: netWorth
        ))
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
            if allSeries.count > 1 {
                ChartLegendView(series: allSeries)
            }
        }
    }

    // MARK: - Axis Marks

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

    // MARK: - Base Chart

    private var baseChart: some View {
        let series = allSeries
        return MultiSeriesChart(series: series)
            .chartYAxis(.hidden)
            .chartXAxis { axisMarks }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    let plotFrame = proxy.plotFrame.map { geo[$0] } ?? geo.frame(in: .local)
                    ZStack(alignment: .topLeading) {
                        if hoverState.hoveredDate != nil {
                            hoverOverlay(proxy: proxy, plotFrame: plotFrame, series: series)
                        }
                        Color.clear.contentShape(Rectangle())
                            .onContinuousHover { phase in
                                switch phase {
                                case let .active(loc):
                                    let plotX = loc.x - plotFrame.origin.x
                                    if let date = proxy.value(atX: plotX, as: Date.self) {
                                        hoverState = buildHoverState(for: date, series: series)
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
    private func hoverOverlay(proxy: ChartProxy, plotFrame: CGRect, series: [ChartSeries]) -> some View {
        if let hoveredDate = hoverState.hoveredDate,
           let plotX = proxy.position(forX: hoveredDate) {
            let xPos = plotX + plotFrame.origin.x

            // Vertical crosshair
            Path { path in
                path.move(to: CGPoint(x: xPos, y: plotFrame.origin.y))
                path.addLine(to: CGPoint(x: xPos, y: plotFrame.maxY))
            }
            .stroke(
                AppColors.Text.quaternary.opacity(0.5),
                style: StrokeStyle(lineWidth: 1, dash: [3, 3])
            )
            .allowsHitTesting(false)

            // Dots on each series at the hovered date
            ForEach(series) { ser in
                if let point = hoverState.seriesValues[ser.id],
                   let plotY = proxy.position(forY: Double(point.netWorthMinorUnits) / 100) {
                    Circle()
                        .fill(ser.color)
                        .stroke(AppColors.base, lineWidth: 1.5)
                        .frame(width: 7, height: 7)
                        .position(x: xPos, y: plotY + plotFrame.origin.y)
                        .allowsHitTesting(false)
                }
            }

            // Tooltip
            MultiSeriesHoverTooltip(
                date: hoveredDate,
                series: series,
                seriesValues: hoverState.seriesValues
            )
            .offset(
                x: plotX > plotFrame.width * 0.6 ? xPos - 180 : xPos + 12,
                y: plotFrame.origin.y + 8
            )
            .allowsHitTesting(false)
        }
    }

    // MARK: - Hover Logic

    private func buildHoverState(for date: Date, series: [ChartSeries]) -> ChartHoverState {
        var values: [UUID: NetWorthPoint] = [:]
        var snappedDate: Date?
        for ser in series {
            if let nearest = ser.nearestPoint(to: date) {
                values[ser.id] = nearest
                // Snap date to the nearest point in the primary (net worth) series.
                if ser.isDashed { snappedDate = nearest.timestamp }
            }
        }
        return ChartHoverState(hoveredDate: snappedDate ?? date, seriesValues: values)
    }
}

// MARK: - MultiSeriesChart (private subview)

private struct MultiSeriesChart: View {
    let series: [ChartSeries]

    var body: some View {
        Chart {
            ForEach(series) { ser in
                // Area fill only for net worth total line.
                if ser.isDashed {
                    ForEach(ser.points) { item in
                        AreaMark(
                            x: .value("Date", item.timestamp),
                            y: .value("Balance", Double(item.netWorthMinorUnits) / 100)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.accentBlue.opacity(0.15), .clear],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                ForEach(ser.points) { item in
                    LineMark(
                        x: .value("Date", item.timestamp),
                        y: .value("Balance", Double(item.netWorthMinorUnits) / 100)
                    )
                    .foregroundStyle(ser.color)
                    .lineStyle(StrokeStyle(
                        lineWidth: ser.lineWidth,
                        dash: ser.isDashed ? [6, 4] : []
                    ))
                    .interpolationMethod(.catmullRom)
                }
            }
        }
    }
}

// MARK: - Legend

private struct ChartLegendView: View {
    let series: [ChartSeries]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(series) { ser in
                    HStack(spacing: 6) {
                        legendIndicator(for: ser)
                        FDSLabel(ser.label)
                            .font(AppTypography.captionSm)
                            .foregroundStyle(AppColors.Text.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    @ViewBuilder
    private func legendIndicator(for series: ChartSeries) -> some View {
        if series.isDashed {
            // Dashed line indicator for total net worth
            HStack(spacing: 2) {
                ForEach(0 ..< 3, id: \.self) { _ in
                    Capsule()
                        .fill(series.color)
                        .frame(width: 5, height: 2)
                }
            }
        } else {
            Circle().fill(series.color).frame(width: 8, height: 8)
        }
    }
}

// MARK: - Multi-series Tooltip

private struct MultiSeriesHoverTooltip: View {
    let date: Date
    let series: [ChartSeries]
    let seriesValues: [UUID: NetWorthPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            FDSLabel(FormatterCache.formatDate(date))
                .font(AppTypography.captionSmSemibold)
                .foregroundStyle(AppColors.Text.tertiary)
            ForEach(series) { ser in
                if let serPoint = seriesValues[ser.id] {
                    tooltipRow(ser.label, value: fmt(Decimal(serPoint.netWorthMinorUnits) / 100), color: ser.color)
                }
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
            FDSLabel(label)
                .font(AppTypography.captionSm)
                .foregroundStyle(AppColors.Text.secondary)
            Spacer(minLength: 8)
            FDSLabel(value)
                .font(AppTypography.captionSmSemibold)
                .foregroundStyle(AppColors.Text.primary)
                .monospacedDigit()
        }
        .frame(minWidth: 140)
    }

    private func fmt(_ value: Decimal) -> String {
        FormatterCache.formatCurrency(value, currencyCode: "INR")
    }
}
