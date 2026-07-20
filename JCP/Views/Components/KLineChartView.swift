import SwiftUI
import Charts

struct KLineChartView: View {
    let data: [KLineData]

    @State private var visibleLower: Int = 0

    var body: some View {
        if data.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "chart.line.downtrend.xyaxis")
                    .font(.title)
                    .foregroundColor(.secondary)
                Text("暂无K线数据")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 0) {
                let rangeSize = min(60, data.count)
                let upperBound = min(visibleLower + rangeSize, data.count)
                let lowerBound = upperBound - rangeSize
                let visibleData = Array(data[lowerBound..<upperBound])

                Chart(Array(visibleData.enumerated()), id: \.offset) { idx, item in
                    let realIdx = lowerBound + idx

                    // K线实体
                    RectangleMark(
                        x: .value("", realIdx),
                        yStart: .value("", item.open),
                        yEnd: .value("", item.close),
                        width: .fixed(6)
                    )
                    .foregroundStyle(item.close >= item.open ? Color.red : Color.green)

                    // 影线
                    RectangleMark(
                        x: .value("", realIdx),
                        yStart: .value("", item.low),
                        yEnd: .value("", item.high),
                        width: .fixed(1)
                    )
                    .foregroundStyle(item.close >= item.open ? Color.red : Color.green)

                    // MA5
                    if let ma5 = item.ma5 {
                        LineMark(
                            x: .value("", realIdx),
                            y: .value("", ma5)
                        )
                        .foregroundStyle(Color.orange)
                        .lineStyle(StrokeStyle(lineWidth: 1))
                    }

                    // MA10
                    if let ma10 = item.ma10 {
                        LineMark(
                            x: .value("", realIdx),
                            y: .value("", ma10)
                        )
                        .foregroundStyle(Color.blue)
                        .lineStyle(StrokeStyle(lineWidth: 1))
                    }

                    // MA20
                    if let ma20 = item.ma20 {
                        LineMark(
                            x: .value("", realIdx),
                            y: .value("", ma20)
                        )
                        .foregroundStyle(Color.purple)
                        .lineStyle(StrokeStyle(lineWidth: 1))
                    }
                }
                .chartXScale(domain: lowerBound...(upperBound - 1))
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 5))
                }
                .chartPlotStyle { plot in
                    plot.padding(.horizontal, 4)
                }

                // 图例
                HStack(spacing: 16) {
                    legendItem("MA5", color: .orange)
                    legendItem("MA10", color: .blue)
                    legendItem("MA20", color: .purple)
                }
                .font(.caption2)
                .padding(.top, 6)

                // 滑动提示
                if data.count > 60 {
                    Text("← 左右滑动查看更多 →")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let delta = Int(value.translation.width / 15)
                        visibleLower = max(0, min(data.count - min(60, data.count), visibleLower - delta))
                    }
            )
        }
    }

    private func legendItem(_ label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).foregroundColor(.secondary)
        }
    }
}
