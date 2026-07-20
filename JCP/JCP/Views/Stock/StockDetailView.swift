import SwiftUI

struct StockDetailView: View {
    @EnvironmentObject var marketService: MarketService
    @State private var selectedPeriod: TimePeriod = .day1

    var body: some View {
        Group {
            if let stock = marketService.currentStock {
                ScrollView {
                    VStack(spacing: 0) {
                        // Price header
                        priceHeader(stock)

                        Divider()

                        // K-line chart
                        periodPicker
                        KLineChartView(data: marketService.klineData)
                            .frame(height: 280)
                            .padding(.vertical, 8)

                        Divider()

                        // Trade info
                        tradeInfoGrid(stock)

                        Divider()

                        // Action buttons
                        actionButtons(stock)
                    }
                }
                .navigationTitle(stock.name)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                ContentUnavailableView("请选择股票", systemImage: "chart.line.uptrend.xyaxis")
            }
        }
    }

    // MARK: - Price Header

    private func priceHeader(_ stock: Stock) -> some View {
        VStack(spacing: 4) {
            Text(String(format: "%.2f", stock.price))
                .font(.system(size: 42, weight: .bold, design: .monospaced))
                .foregroundColor(stock.changePercent >= 0 ? .red : .green)

            HStack(spacing: 8) {
                Text(String(format: "%+.2f", stock.change))
                    .font(.title3)
                Text(String(format: "%+.2f%%", stock.changePercent))
                    .font(.title3)
            }
            .foregroundColor(stock.changePercent >= 0 ? .red : .green)
        }
        .padding(.vertical, 16)
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        Picker("周期", selection: $selectedPeriod) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Text(period.displayName).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .onChange(of: selectedPeriod) { _, period in
            Task {
                await marketService.refreshKLine(
                    symbol: marketService.currentStock?.symbol ?? "",
                    period: period
                )
            }
        }
    }

    // MARK: - Trade Info Grid

    private func tradeInfoGrid(_ stock: Stock) -> some View {
        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 12) {
            infoCell("开盘", String(format: "%.2f", stock.open))
            infoCell("最高", String(format: "%.2f", stock.high))
            infoCell("最低", String(format: "%.2f", stock.low))
            infoCell("昨收", String(format: "%.2f", stock.preClose))
            infoCell("成交量", formatVolume(stock.volume))
            infoCell("成交额", formatAmount(stock.amount))
        }
        .padding()
    }

    private func infoCell(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    // MARK: - Actions

    private func actionButtons(_ stock: Stock) -> some View {
        VStack(spacing: 12) {
            NavigationLink {
                MeetingRoomView(stock: stock)
            } label: {
                Label("进入会议室分析", systemImage: "person.3.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            HStack(spacing: 12) {
                Button {
                    // Add to watchlist
                } label: {
                    Label("加自选", systemImage: "star")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    // F10
                } label: {
                    Label("F10", systemImage: "doc.text")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    // MARK: - Format helpers

    private func formatVolume(_ v: Double) -> String {
        if v > 1_0000_0000 { return String(format: "%.2f亿手", v / 1_0000_0000) }
        if v > 1_0000 { return String(format: "%.2f万手", v / 1_0000) }
        return "\(Int(v))手"
    }

    private func formatAmount(_ a: Double) -> String {
        if a > 1_0000_0000 { return String(format: "%.2f亿", a / 1_0000_0000) }
        if a > 1_0000 { return String(format: "%.2f万", a / 1_0000) }
        return "\(Int(a))"
    }
}
