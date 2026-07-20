import SwiftUI

struct TelegraphNewsView: View {
    @EnvironmentObject var marketVM: MarketViewModel
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.jcpBackground.ignoresSafeArea()

                List {
                    ForEach(marketVM.telegraphs) { item in
                        HStack(alignment: .top, spacing: 10) {
                            Text(item.time)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.jcpTextTertiary)
                                .frame(width: 40)

                            Circle()
                                .fill(Color.jcpRed)
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)

                            Text(item.content)
                                .font(.subheadline)
                                .foregroundColor(.jcpTextPrimary)
                                .lineLimit(3)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color.jcpBackground)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable {
                    refresh()
                }
            }
            .navigationTitle("News Feed")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func refresh() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            marketVM.loadTelegraphs()
            isLoading = false
        }
    }
}

// MARK: - Research Reports View

struct ResearchReportsView: View {
    @State private var reports = MockDataService.shared.generateResearchReports()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.jcpBackground.ignoresSafeArea()

                List(reports) { report in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(report.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.jcpTextPrimary)
                            .lineLimit(2)

                        HStack(spacing: 8) {
                            Text(report.orgName)
                                .font(.caption)
                                .foregroundColor(.jcpTextSecondary)

                            Text(report.rating)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(ratingColor(report.rating).opacity(0.15))
                                .foregroundColor(ratingColor(report.rating))
                                .cornerRadius(4)

                            Spacer()

                            Text(report.publishDate)
                                .font(.caption2)
                                .foregroundColor(.jcpTextTertiary)
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.jcpBackground)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Research Reports")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func ratingColor(_ rating: String) -> Color {
        if rating.contains("??") || rating.contains("?") { return .jcpRed }
        if rating.contains("??") { return .orange }
        return .jcpTextSecondary
    }
}

// MARK: - Position Management View

struct PositionView: View {
    let stock: Stock
    @State private var shares: String = ""
    @State private var costPrice: String = ""
    @State private var showResult = false
    @State private var resultText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Stock") {
                    HStack {
                        Text(stock.name)
                            .foregroundColor(.jcpTextPrimary)
                        Text(stock.symbol)
                            .font(.caption)
                            .foregroundColor(.jcpTextTertiary)
                    }
                }

                Section("Position") {
                    HStack {
                        Text("Shares")
                            .foregroundColor(.jcpTextSecondary)
                        TextField("0", text: $shares)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.jcpTextPrimary)
                    }
                    HStack {
                        Text("Cost Price")
                            .foregroundColor(.jcpTextSecondary)
                        TextField("0.00", text: $costPrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.jcpTextPrimary)
                    }
                }

                if showResult {
                    Section("P&L Estimate") {
                        HStack {
                            Text("Market Value")
                            Spacer()
                            Text("\(stock.price.formatPrice())")
                                .foregroundColor(.jcpTextPrimary)
                        }
                        HStack {
                            Text("P&L")
                            Spacer()
                            Text(pnlText)
                                .fontWeight(.bold)
                                .foregroundColor(pnlColor)
                        }
                    }
                }

                Section {
                    Button("Calculate") {
                        calculate()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.jcpAccent)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.jcpBackground)
            .navigationTitle("Position")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var pnlText: String {
        guard let s = Int64(shares), s > 0, let c = Double(costPrice), c > 0 else { return "-" }
        let pnl = (stock.price - c) * Double(s)
        let pnlRatio = (stock.price - c) / c * 100
        return String(format: "%.2f (%.2f%%)", pnl, pnlRatio)
    }

    private var pnlColor: Color {
        guard let s = Int64(shares), s > 0, let c = Double(costPrice), c > 0 else { return .jcpTextSecondary }
        return stock.price >= c ? .jcpRed : .jcpGreen
    }

    private func calculate() {
        guard let s = Int64(shares), s > 0, let c = Double(costPrice), c > 0 else {
            resultText = "Please enter valid shares and cost price"
            showResult = true
            return
        }
        showResult = true
    }
}
