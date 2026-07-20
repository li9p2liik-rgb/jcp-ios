import SwiftUI

struct MarketTabView: View {
    @EnvironmentObject var marketService: MarketService
    @State private var searchText = ""
    @State private var searchResults: [Stock] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    private let quickStocks: [(String, String)] = [
        ("sh601899", "紫金矿业"),
        ("sz000858", "五粮液"),
        ("sh600519", "贵州茅台"),
        ("sz300750", "宁德时代"),
        ("sh601398", "工商银行"),
        ("sz002594", "比亚迪"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Top indices bar
            MarketIndexBar()

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("搜索股票代码或名称", text: $searchText)
                    .textFieldStyle(.plain)
                    .onChange(of: searchText) { _, newValue in
                        performSearch(newValue)
                    }
                if !searchText.isEmpty {
                    Button { clearSearch() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top, 8)

            // Content
            if isSearching {
                searchResultList
            } else {
                defaultContent
            }
        }
        .navigationTitle("行情")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Default content

    private var defaultContent: some View {
        List {
            Section("快速查看") {
                ForEach(quickStocks, id: \.0) { symbol, name in
                    Button {
                        Task {
                            let stock = Stock(
                                symbol: symbol, name: name,
                                price: 0, change: 0, changePercent: 0,
                                volume: 0, amount: 0,
                                marketCap: "", sector: "",
                                open: 0, high: 0, low: 0, preClose: 0
                            )
                            await marketService.selectStock(stock)
                        }
                    } label: {
                        HStack {
                            Text(name)
                                .foregroundColor(.primary)
                            Spacer()
                            Text(symbol.uppercased())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Section("市场状态") {
                if let status = marketService.marketStatus {
                    HStack {
                        Circle()
                            .fill(status.status == "trading" ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        Text(status.statusText)
                        Spacer()
                        Text(status.isTradeDay ? "交易日" : "休市")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Search results

    private var searchResultList: some View {
        Group {
            if searchResults.isEmpty && !searchText.isEmpty {
                ContentUnavailableView("未找到结果", systemImage: "magnifyingglass")
            } else {
                List(searchResults) { stock in
                    Button {
                        Task { await marketService.selectStock(stock) }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(stock.name)
                                    .foregroundColor(.primary)
                                Text(stock.symbol.uppercased())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func performSearch(_ query: String) {
        searchTask?.cancel()
        guard !query.isEmpty else {
            isSearching = false
            searchResults = []
            return
        }
        isSearching = true
        searchTask = Task {
            await marketService.search(query)
            guard !Task.isCancelled else { return }
            searchResults = marketService.searchResults
        }
    }

    private func clearSearch() {
        searchText = ""
        isSearching = false
        searchResults = []
    }
}
