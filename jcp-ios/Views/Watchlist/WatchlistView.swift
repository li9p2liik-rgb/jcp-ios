import SwiftUI

struct WatchlistView: View {
    @EnvironmentObject var watchlistVM: WatchlistViewModel
    @State private var showSearch = false
    @State private var selectedStock: Stock?
    @State private var showDetail = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.jcpBackground.ignoresSafeArea()
                
                if watchlistVM.isLoading {
                    ProgressView()
                        .tint(.jcpAccent)
                } else {
                    VStack(spacing: 0) {
                        // 市场状态栏
                        marketStatusBar
                        
                        // 大盘指数
                        MarketIndicesView(indices: watchlistVM.marketIndices)
                        
                        // 自选股列表
                        if watchlistVM.stocks.isEmpty {
                            emptyState
                        } else {
                            watchlistHeader
                            stockList
                        }
                    }
                }
            }
            .navigationTitle("自选股")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { watchlistVM.loadData() }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSearch = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.jcpAccent)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { watchlistVM.refresh() }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.jcpAccent)
                    }
                }
            }
            .sheet(isPresented: $showSearch) {
                StockSearchView { stock in
                    watchlistVM.addStock(symbol: stock.symbol)
                    showSearch = false
                }
            }
            .navigationDestination(isPresented: $showDetail) {
                if let stock = selectedStock {
                    StockDetailView(stock: stock)
                }
            }
        }
    }
    
    private var marketStatusBar: some View {
        HStack {
            if let status = watchlistVM.marketStatus {
                Circle()
                    .fill(status.status.isTrading ? Color.jcpGreen : Color.jcpTextTertiary)
                    .frame(width: 8, height: 8)
                Text(status.statusText)
                    .font(.caption)
                    .foregroundColor(.jcpTextSecondary)
            }
            Spacer()
            Text(Date(), style: .time)
                .font(.caption)
                .foregroundColor(.jcpTextTertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.jcpCardBackground)
    }
    
    private var watchlistHeader: some View {
        HStack {
            Text("名称")
                .font(.caption)
                .foregroundColor(.jcpTextTertiary)
            Spacer()
            Text("现价")
                .font(.caption)
                .foregroundColor(.jcpTextTertiary)
                
            Text("涨跌幅")
                .font(.caption)
                .foregroundColor(.jcpTextTertiary)
                
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
    
    private var stockList: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(watchlistVM.stocks) { stock in
                    StockRowView(stock: stock)
                        .onTapGesture {
                            selectedStock = stock
                            showDetail = true
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                withAnimation {
                                    watchlistVM.removeStock(symbol: stock.symbol)
                                }
                            } label: {
                                Label("删除自选", systemImage: "star.slash")
                            }
                        }
                }
            }
            .background(Color.jcpCardBackground)
            .cornerRadius(12)
            .padding(.horizontal, 8)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.slash")
                .font(.system(size: 50))
                .foregroundColor(.jcpTextTertiary)
            Text("还没有自选股")
                .font(.headline)
                .foregroundColor(.jcpTextSecondary)
            Text("点击右上角 + 添加股票")
                .font(.subheadline)
                .foregroundColor(.jcpTextTertiary)
            Button(action: { showSearch = true }) {
                Text("添加自选股")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.jcpAccent)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .frame(maxHeight: .infinity)
    }
}

struct StockRowView: View {
    let stock: Stock
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.name)
                    .font(.headline)
                    .foregroundColor(.jcpTextPrimary)
                Text(stock.symbol)
                    .font(.caption)
                    .foregroundColor(.jcpTextTertiary)
            }
            
            Spacer()
            
            // 现价
            Text(stock.price.formatPrice())
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.jcpTextPrimary)
                
            
            // 涨跌幅
            VStack(alignment: .trailing, spacing: 2) {
                Text(stock.changePercent.formatPercent())
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(stock.change.formatChange())
                    .font(.caption)
            }
            
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(stock.changePercent >= 0 ? Color.jcpRed.opacity(0.15) : Color.jcpGreen.opacity(0.15))
            .cornerRadius(6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.jcpCardBackground)
    }
}

struct MarketIndicesView: View {
    let indices: [MarketIndex]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(indices) { index in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(index.name)
                            .font(.caption)
                            .foregroundColor(.jcpTextSecondary)
                        Text(index.price.formatPrice())
                            .font(.headline)
                            .foregroundColor(.jcpTextPrimary)
                        Text(index.changePercent.formatPercent())
                            .font(.caption)
                            .foregroundColor(index.changePercent >= 0 ? .jcpRed : .jcpGreen)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.jcpCardBackground)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
    }
}
