import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 1 // 默认选中自选
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MarketOverviewView()
                .tabItem {
                    Image(systemName: "chart.bar.xaxis")
                    Text("行情")
                }
                .tag(0)
            
            WatchlistView()
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("自选")
                }
                .tag(1)
            
            AgentRoomEntryView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("AI智库")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("我的")
                }
                .tag(3)
        }
        .tint(Color.jcpAccent)
        .onAppear {
            setupAppearance()
        }
    }
    
    private func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.jcpCardBackground)
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.jcpAccent)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.jcpAccent)]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.jcpTextTertiary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.jcpTextTertiary)]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - AI 智库入口视图
struct AgentRoomEntryView: View {
    @EnvironmentObject var watchlistVM: WatchlistViewModel
    @State private var selectedStock: Stock?
    @State private var showAgentRoom = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 头部
                VStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 50))
                        .foregroundColor(.jcpAccent)
                    Text("AI 智库")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.jcpTextPrimary)
                    Text("多 Agent 协作分析，让投资决策更智能")
                        .font(.subheadline)
                        .foregroundColor(.jcpTextSecondary)
                }
                .padding(.top, 30)
                
                // 选择股票
                VStack(alignment: .leading, spacing: 12) {
                    Text("选择分析标的")
                        .font(.headline)
                        .foregroundColor(.jcpTextPrimary)
                    
                    if watchlistVM.stocks.isEmpty {
                        Text("暂无自选股，请先在自选页面添加股票")
                            .foregroundColor(.jcpTextTertiary)
                            .padding()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(watchlistVM.stocks) { stock in
                                    AgentStockRow(stock: stock, isSelected: selectedStock?.symbol == stock.symbol)
                                        .onTapGesture {
                                            selectedStock = stock
                                        }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 开始分析按钮
                Button(action: {
                    if selectedStock != nil {
                        showAgentRoom = true
                    }
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("开始分析")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedStock != nil ? Color.jcpAccent : Color.jcpSurface)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(selectedStock == nil)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(Color.jcpBackground)
            .navigationDestination(isPresented: $showAgentRoom) {
                if let stock = selectedStock {
                    AgentRoomView(stock: stock)
                }
            }
        }
    }
}

struct AgentStockRow: View {
    let stock: Stock
    let isSelected: Bool
    
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
            
            Text(stock.price.formatPrice())
                .font(.headline)
                .foregroundColor(.jcpTextPrimary)
            
            Text(stock.changePercent.formatPercent())
                .font(.subheadline)
                .frame(width: 80, alignment: .trailing)
                .foregroundColor(stock.changePercent >= 0 ? .jcpRed : .jcpGreen)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isSelected ? Color.jcpAccent.opacity(0.15) : Color.jcpCardBackground)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.jcpAccent : Color.clear, lineWidth: 1)
        )
    }
}
