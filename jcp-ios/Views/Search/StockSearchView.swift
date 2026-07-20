import SwiftUI

struct StockSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var watchlistVM = WatchlistViewModel()
    @State private var searchText = ""
    @State private var results: [Stock] = []
    let onSelect: (Stock) -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                // 搜索栏
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.jcpTextTertiary)
                    TextField("输入股票代码或名称", text: $searchText)
                        .foregroundColor(.jcpTextPrimary)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: searchText) { _, newValue in
                            searchStocks(newValue)
                        }
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.jcpTextTertiary)
                        }
                    }
                }
                .padding(12)
                .background(Color.jcpCardBackground)
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // 搜索结果
                if results.isEmpty {
                    if searchText.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.jcpTextTertiary)
                            Text("输入股票代码或名称搜索")
                                .foregroundColor(.jcpTextSecondary)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 40))
                                .foregroundColor(.jcpTextTertiary)
                            Text("未找到匹配的股票")
                                .foregroundColor(.jcpTextSecondary)
                        }
                        .frame(maxHeight: .infinity)
                    }
                } else {
                    List(results) { stock in
                        Button(action: { onSelect(stock) }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(stock.name)
                                        .font(.headline)
                                        .foregroundColor(.jcpTextPrimary)
                                    Text(stock.symbol)
                                        .font(.caption)
                                        .foregroundColor(.jcpTextTertiary)
                                    Text(stock.sector)
                                        .font(.caption2)
                                        .foregroundColor(.jcpTextTertiary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(stock.price.formatPrice())
                                        .font(.headline)
                                        .foregroundColor(.jcpTextPrimary)
                                    Text(stock.changePercent.formatPercent())
                                        .font(.subheadline)
                                        .foregroundColor(stock.changePercent >= 0 ? .jcpRed : .jcpGreen)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.jcpBackground)
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color.jcpBackground)
            .navigationTitle("搜索股票")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(.jcpAccent)
                }
            }
        }
    }
    
    private func searchStocks(_ keyword: String) {
        if keyword.isEmpty {
            results = []
            return
        }
        results = MockDataService.shared.searchStocks(keyword: keyword)
    }
}
