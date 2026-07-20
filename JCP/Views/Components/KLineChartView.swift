import SwiftUI
import Charts

struct KLineChartView: View {
    let data: [KLineData]

    @State private var visibleRange: ClosedRange<Int> = 0...100
    @State private var dragOffset: CGFloat = 0

    private let candleWidth: CGFloat = 8
    private let spacing: CGFloat = 1

    var body: some View {
        if data.isEmpty {
            ContentUnavailableView("暂无K线数据", systemImage: "chart.line.downtrend.xyaxis")
        } else {
            GeometryReader { geo in
                let chartWidth = geo.size.width
                let totalWidth = CGFloat(data.count) * (candleWidth + spacing)
                let maxOffset = max(0, totalWidth - chartWidth)

                Chart(Array(data.enumerated()), id: \.offset) { idx, item in
                    // Candlestick body
                    RectangleMark(
                        x: .value("Index", idx),
                        yStart: .value("Open", item.open),
                        yEnd: .value("Close", item.close),
                        width: .fixed(candleWidth)
                    )
                    .foregroundStyle(item.close >= item.open ? Color.red : Color.green)

                    // High-low wick
                    RectangleMark(
                        x: .value("Index", idx),
                        yStart: .value("Low", item.low),
                        yEnd: .value("High", item.high),
                        width: .fixed(1)
                    )
                    .foregroundStyle(item.close >= item.open ? Color.red : Color.green)

                    // MA5 line
                    if let ma5 = item.ma5 {
                        LineMark(
                            x: .value("Index", idx),
                            y: .value("MA5", ma5)
                        )
                        .foregroundStyle(Color.orange)
                        .lineStyle(StrokeStyle(lineWidth: 1))
                    }

                    // MA10 line
                    if let ma10 = item.ma10 {
                        LineMark(
                            x: .value("Index", idx),
                            y: .value("MA10", ma10)
                        )
                        .foregroundStyle(Color.blue)
                        .lineStyle(StrokeStyle(lineWidth: 1))
                    }

                    // MA20 line
                    if let ma20 = item.ma20 {
                        LineMark(
                            x: .value("Index", idx),
                            y: .value("MA20", ma20)
                        )
                        .foregroundStyle(Color.purple)
                        .lineStyle(StrokeStyle(lineWidth: 1))
                    }
                }
                .chartXScale(domain: visibleRange)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                        AxisValueLabel(format: KLineDateFormat())
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 5))
                }
                .chartPlotStyle { plot in
                    plot
                        .padding(.horizontal, 4)
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let delta = value.translation.width / 3
                            let rangeSize = visibleRange.count
                            let step = Int(delta / 20)
                            var newLower = visibleRange.lowerBound - step
                            var newUpper = newLower + rangeSize
                            if newLower < 0 { newLower = 0; newUpper = rangeSize }
                            if newUpper > data.count - 1 { newUpper = data.count - 1; newLower = newUpper - rangeSize }
                            visibleRange = newLower...newUpper
                        }
                )
            }
            // MA Legend
            HStack(spacing: 16) {
                legendItem("MA5", color: .orange)
                legendItem("MA10", color: .blue)
                legendItem("MA20", color: .purple)
            }
            .font(.caption2)
            .padding(.top, 4)
        }
    }

    private func legendItem(_ label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .foregroundColor(.secondary)
        }
    }
}

/// Date formatter for K-line chart x-axis
private struct KLineDateFormat: FormatStyle {
    typealias FormatInput = Int
    typealias FormatOutput = String

    func format(_ value: Int) -> String {
        // Return simplified date - actual impl would parse from KLineData.time
        "\(value)"
    }
}
