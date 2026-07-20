import SwiftUI

struct StockDetailView: View {
    let symbol: String
    let name: String

    @EnvironmentObject var marketService: MarketService
    @State private var stock: Stock?
    @State private var selectedPeriod: TimePeriod = .day1
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("加载行情数据...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else if let stock {
                scrollContent(stock)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("行情加载失败")
                        .foregroundColor(.secondary)
                    Button("重试") { Task { await loadStock() } }
                        .buttonStyle(.bordered)
                }
            }
        }
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadStock() }
    }

    // MARK: - Content

    private func scrollContent(_ stock: Stock) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // 价格头部
                priceHeader(stock)

                Divider()

                // K线
                periodPicker
                KLineChartView(data: marketService.klineData)
                    .frame(height: 280)
                    .padding(.vertical, 8)

                if marketService.klineData.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView("加载K线...")
                            .font(.caption)
                        Spacer()
                    }
                    .frame(height: 280)
                }

                Divider()

                // 交易数据
                tradeInfoGrid(stock)

                Divider()
                    .padding(.vertical, 8)

                // 操作按钮
                actionButtons(stock)
            }
        }
        .onChange(of: selectedPeriod) { _, period in
            Task { await marketService.refreshKLine(symbol: symbol, period: period) }
        }
    }

    // MARK: - 价格头部

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

    // MARK: - K线周期选择

    private var periodPicker: some View {
        Picker("周期", selection: $selectedPeriod) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Text(period.displayName).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    // MARK: - 交易数据

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

    // MARK: - 操作按钮

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
                    // 加自选
                } label: {
                    Label("加自选", systemImage: "star")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    // F10
                } label: {
                    Label("F10 资料", systemImage: "doc.text")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    // MARK: - Helpers

    private func loadStock() async {
        isLoading = true
        await marketService.selectStock(Stock(
            symbol: symbol, name: name,
            price: 0, change: 0, changePercent: 0,
            volume: 0, amount: 0,
            marketCap: "", sector: "",
            open: 0, high: 0, low: 0, preClose: 0
        ))
        isLoading = marketService.currentStock == nil
    }

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
