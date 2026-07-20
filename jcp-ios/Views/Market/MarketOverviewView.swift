import SwiftUI

struct MarketOverviewView: View {
    @EnvironmentObject var marketVM: MarketViewModel
    @State private var selectedSegment = 0
    
    let segments = ["快讯", "热点", "龙虎榜", "异动", "资金流", "研报"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.jcpBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 大盘指数
                    MarketIndicesView(indices: MockDataService.shared.marketIndices)
                    
                    // 分段选择
                    Picker("市场数据", selection: $selectedSegment) {
                        ForEach(0..<segments.count, id: \.self) { i in
                            Text(segments[i]).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    // 内容
                    TabView(selection: $selectedSegment) {
                        HotTrendsView()
                            .tag(0)
                        LongHuBangView()
                            .tag(1)
                        MarketMovesView()
                            .tag(2)
                        BoardFundFlowView()
                            .tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("行情")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                marketVM.loadHotTrends()
            }
        }
    }
}

// MARK: - 热点舆情
struct HotTrendsView: View {
    @EnvironmentObject var marketVM: MarketViewModel
    @State private var selectedPlatform: String = "baidu"
    
    var body: some View {
        VStack(spacing: 0) {
            // 平台选择
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Constants.hotTrendPlatforms, id: \.id) { platform in
                        Button(action: { selectedPlatform = platform.id }) {
                            HStack(spacing: 4) {
                                Image(systemName: platform.icon)
                                    .font(.caption)
                                Text(platform.name)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedPlatform == platform.id ? Color.jcpAccent : Color.jcpSurface)
                            .foregroundColor(selectedPlatform == platform.id ? .white : .jcpTextSecondary)
                            .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
            
            // 列表
            if let trend = marketVM.hotTrends.first(where: { $0.platform == selectedPlatform }) {
                List(trend.items) { item in
                    HStack(spacing: 12) {
                        // 排名
                        Text("\(item.rank)")
                            .font(.headline)
                            .foregroundColor(item.rank <= 3 ? .jcpRed : .jcpTextSecondary)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.subheadline)
                                .foregroundColor(.jcpTextPrimary)
                                .lineLimit(2)
                            HStack(spacing: 8) {
                                Text("热度")
                                    .font(.system(size: 10))
                                    .foregroundColor(.jcpTextTertiary)
                                Text("\(item.hot)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.jcpAccent)
                            }
                        }
                        
                        Spacer()
                        
                        if item.rank <= 3 {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.jcpBackground)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable {
                    marketVM.loadHotTrends()
                }
            } else {
                Spacer()
                ProgressView()
                Spacer()
            }
        }
        .background(Color.jcpBackground)
    }
}

// MARK: - 龙虎榜
struct LongHuBangView: View {
    @EnvironmentObject var marketVM: MarketViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if marketVM.longHuBangItems.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "tiger")
                        .font(.system(size: 40))
                        .foregroundColor(.jcpTextTertiary)
                    Text("点击加载龙虎榜数据")
                        .foregroundColor(.jcpTextSecondary)
                    Button("加载数据") {
                        marketVM.loadLongHuBang()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.jcpAccent)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                Spacer()
            } else {
                // 表头
                HStack {
                    Text("名称").frame(maxWidth: .infinity, alignment: .leading)
                    Text("类型").frame(width: 80)
                    Text("净买入").frame(width: 100, alignment: .trailing)
                }
                .font(.caption)
                .foregroundColor(.jcpTextTertiary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                List(marketVM.longHuBangItems) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.subheadline)
                                .foregroundColor(.jcpTextPrimary)
                            Text(item.symbol)
                                .font(.system(size: 10))
                                .foregroundColor(.jcpTextTertiary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(item.typeName)
                            .font(.system(size: 10))
                            .foregroundColor(.jcpAccent)
                            .frame(width: 80)
                        
                        Text(item.netAmount.formatAmount())
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(item.netAmount >= 0 ? .jcpRed : .jcpGreen)
                            .frame(width: 100, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.jcpBackground)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable {
                    marketVM.loadLongHuBang()
                }
            }
        }
        .background(Color.jcpBackground)
    }
}

// MARK: - 盘口异动
struct MarketMovesView: View {
    @EnvironmentObject var marketVM: MarketViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if marketVM.marketMoves.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.jcpTextTertiary)
                    Text("点击加载盘口异动")
                        .foregroundColor(.jcpTextSecondary)
                    Button("加载数据") {
                        marketVM.loadMarketMoves()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.jcpAccent)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                Spacer()
            } else {
                List(marketVM.marketMoves) { move in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(move.name)
                                .font(.subheadline)
                                .foregroundColor(.jcpTextPrimary)
                            Text(move.symbol)
                                .font(.system(size: 10))
                                .foregroundColor(.jcpTextTertiary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(move.moveTypeName)
                                .font(.system(size: 11))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(move.moveType == "limit_up" ? Color.jcpRed.opacity(0.2) : move.moveType == "limit_down" ? Color.jcpGreen.opacity(0.2) : Color.jcpAccent.opacity(0.2))
                                .foregroundColor(move.moveType == "limit_up" ? .jcpRed : move.moveType == "limit_down" ? .jcpGreen : .jcpAccent)
                                .cornerRadius(4)
                            
                            Text(move.time)
                                .font(.system(size: 10))
                                .foregroundColor(.jcpTextTertiary)
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.jcpBackground)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable {
                    marketVM.loadMarketMoves()
                }
            }
        }
        .background(Color.jcpBackground)
    }
}

// MARK: - 板块资金流
struct BoardFundFlowView: View {
    @EnvironmentObject var marketVM: MarketViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if marketVM.boardFundFlows.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 40))
                        .foregroundColor(.jcpTextTertiary)
                    Text("点击加载板块资金流")
                        .foregroundColor(.jcpTextSecondary)
                    Button("加载数据") {
                        marketVM.loadBoardFundFlow()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.jcpAccent)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                Spacer()
            } else {
                // 表头
                HStack {
                    Text("排名")
                        .frame(width: 40, alignment: .leading)
                    Text("板块")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("资金流向")
                        .frame(width: 120, alignment: .trailing)
                }
                .font(.caption)
                .foregroundColor(.jcpTextTertiary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                List(marketVM.boardFundFlows) { flow in
                    HStack {
                        Text("\(flow.rank)")
                            .font(.subheadline)
                            .foregroundColor(flow.rank <= 3 ? .jcpRed : .jcpTextSecondary)
                            .frame(width: 40, alignment: .leading)
                        
                        Text(flow.boardName)
                            .font(.subheadline)
                            .foregroundColor(.jcpTextPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(flow.fundFlow.formatAmount())
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(flow.fundFlow >= 0 ? .jcpRed : .jcpGreen)
                            .frame(width: 120, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.jcpBackground)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable {
                    marketVM.loadBoardFundFlow()
                }
            }
        }
        .background(Color.jcpBackground)
    }
}
