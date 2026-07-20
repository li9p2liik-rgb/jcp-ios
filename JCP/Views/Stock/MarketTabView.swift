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
            // 大盘指数条
            MarketIndexBar()

            // 搜索栏
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

            // 内容区
            if isSearching {
                searchResultList
            } else {
                defaultContent
            }
        }
        .navigationTitle("行情")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 默认内容

    private var defaultContent: some View {
        List {
            Section("快速查看") {
                ForEach(quickStocks, id: \.0) { symbol, name in
                    NavigationLink {
                        StockDetailView(symbol: symbol, name: name)
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
                } else {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("获取市场状态中...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - 搜索结果

    private var searchResultList: some View {
        Group {
            if searchResults.isEmpty && !searchText.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("未找到 \"\(searchText)\"")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List(searchResults) { stock in
                    NavigationLink {
                        StockDetailView(symbol: stock.symbol, name: stock.name)
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

    // MARK: - 操作

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
