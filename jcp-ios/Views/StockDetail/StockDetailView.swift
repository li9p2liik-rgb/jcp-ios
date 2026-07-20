import SwiftUI
import Charts

struct StockDetailView: View {
    let stock: Stock
    @StateObject private var viewModel = StockDetailViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            Color.jcpBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 股票基本信息
                stockHeader
                
                // 分页标签
                tabSelector
                
                // 内容
                TabView(selection: $selectedTab) {
                    KLineChartView(data: viewModel.kLineData, stock: stock)
                        .tag(0)
                    
                    OrderBookView(orderBook: viewModel.orderBook)
                        .tag(1)
                    
                    F10OverviewView(f10Data: viewModel.f10Data, isLoading: viewModel.isLoadingF10)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .navigationTitle(stock.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadStock(code: stock.symbol)
        }
    }
    
    private var stockHeader: some View {
        VStack(spacing: 8) {
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                Text(stock.price.formatPrice())
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(stock.changePercent >= 0 ? .jcpRed : .jcpGreen)
                
                Text(stock.changePercent.formatPercent())
                    .font(.title3)
                    .foregroundColor(stock.changePercent >= 0 ? .jcpRed : .jcpGreen)
                
                Text("涨跌 \(stock.change.formatChange())")
                    .font(.subheadline)
                    .foregroundColor(stock.changePercent >= 0 ? .jcpRed : .jcpGreen)
            }
            
            HStack(spacing: 20) {
                infoItem("今开", stock.open.formatPrice())
                infoItem("最高", stock.high.formatPrice())
                infoItem("最低", stock.low.formatPrice())
                infoItem("昨收", stock.preClose.formatPrice())
                infoItem("成交量", stock.volume.formatVolume())
                infoItem("成交额", stock.amount.formatAmount())
            }
            .font(.caption)
        }
        .padding()
        .background(Color.jcpCardBackground)
    }
    
    private func infoItem(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .foregroundColor(.jcpTextTertiary)
            Text(value)
                .foregroundColor(.jcpTextPrimary)
                .fontWeight(.medium)
        }
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(["K线", "盘口", "F10"], id: \.self) { tab in
                Button(action: { selectedTab = ["K线", "盘口", "F10"].firstIndex(of: tab) ?? 0 }) {
                    Text(tab)
                        .fontWeight(selectedTab == (["K线", "盘口", "F10"].firstIndex(of: tab) ?? 0) ? .bold : .regular)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundColor(selectedTab == (["K线", "盘口", "F10"].firstIndex(of: tab) ?? 0) ? .jcpAccent : .jcpTextSecondary)
                }
                .background(
                    VStack {
                        Spacer()
                        if selectedTab == (["K线", "盘口", "F10"].firstIndex(of: tab) ?? 0) {
                            Rectangle()
                                .fill(Color.jcpAccent)
                                .frame(height: 2)
                        }
                    }
                )
            }
        }
        .background(Color.jcpCardBackground)
    }
}

// MARK: - K线图表
struct KLineChartView: View {
    let data: [KLineData]
    let stock: Stock
    @State private var selectedPeriod = "1d"
    
    let periods = ["1m", "5m", "1d", "1w", "1mo"]
    let periodLabels = ["1分", "5分", "日线", "周线", "月线"]
    
    var body: some View {
        VStack(spacing: 0) {
            // 周期选择
            HStack(spacing: 8) {
                ForEach(Array(zip(periods, periodLabels)), id: \.0) { (period, label) in
                    Button(action: { selectedPeriod = period }) {
                        Text(label)
                            .font(.caption)
                            .fontWeight(selectedPeriod == period ? .bold : .regular)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(selectedPeriod == period ? Color.jcpAccent : Color.jcpSurface)
                            .foregroundColor(selectedPeriod == period ? .white : .jcpTextSecondary)
                            .cornerRadius(4)
                    }
                }
            }
            .padding(8)
            
            // K线图
            if data.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                candleChart
                
                // 成交量
                volumeChart
                
                // 统计信息
                statsBar
            }
        }
        .background(Color.jcpBackground)
        .onChange(of: selectedPeriod) { _, _ in
            // 重新加载数据
        }
    }
    
    private var candleChart: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let count = data.count
            guard count > 0 else { return AnyView(Text("")) }
            
            let maxPrice = data.map { $0.high }.max() ?? 0
            let minPrice = data.map { $0.low }.min() ?? 0
            let priceRange = maxPrice - minPrice > 0 ? maxPrice - minPrice : 1
            let candleWidth = max(3, width / CGFloat(count) - 1)
            
            return AnyView(
                ZStack {
                    // 网格线
                    VStack(spacing: 0) {
                        ForEach(0..<4, id: \.self) { i in
                            Divider()
                                .opacity(0.3)
                            Spacer()
                        }
                        Divider()
                            .opacity(0.3)
                    }
                    
                    // MA 均线
                    if data.contains(where: { $0.ma5 != nil }) {
                        Path { path in
                            for (index, item) in data.enumerated() {
                                guard let ma5 = item.ma5 else { continue }
                                let x = CGFloat(index) * (candleWidth + 1) + candleWidth / 2
                                let y = height - CGFloat((ma5 - minPrice) / priceRange) * height * 0.9 - height * 0.05
                                if index == 0 { path.move(to: CGPoint(x: x, y: y)) }
                                else { path.addLine(to: CGPoint(x: x, y: y)) }
                            }
                        }
                        .stroke(Color.blue.opacity(0.6), lineWidth: 1)
                    }
                    
                    if data.contains(where: { $0.ma10 != nil }) {
                        Path { path in
                            for (index, item) in data.enumerated() {
                                guard let ma10 = item.ma10 else { continue }
                                let x = CGFloat(index) * (candleWidth + 1) + candleWidth / 2
                                let y = height - CGFloat((ma10 - minPrice) / priceRange) * height * 0.9 - height * 0.05
                                if index == 0 { path.move(to: CGPoint(x: x, y: y)) }
                                else { path.addLine(to: CGPoint(x: x, y: y)) }
                            }
                        }
                        .stroke(Color.orange.opacity(0.6), lineWidth: 1)
                    }
                    
                    // K线
                    ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                        let x = CGFloat(index) * (candleWidth + 1)
                        let isUp = item.close >= item.open
                        let color: Color = isUp ? .jcpRed : .jcpGreen
                        
                        // 影线
                        let highY = height - CGFloat((item.high - minPrice) / priceRange) * height * 0.9 - height * 0.05
                        let lowY = height - CGFloat((item.low - minPrice) / priceRange) * height * 0.9 - height * 0.05
                        let openY = height - CGFloat((item.open - minPrice) / priceRange) * height * 0.9 - height * 0.05
                        let closeY = height - CGFloat((item.close - minPrice) / priceRange) * height * 0.9 - height * 0.05
                        
                        Path { path in
                            path.move(to: CGPoint(x: x + candleWidth / 2, y: highY))
                            path.addLine(to: CGPoint(x: x + candleWidth / 2, y: lowY))
                        }
                        .stroke(color, lineWidth: 0.5)
                        
                        // 实体
                        Rectangle()
                            .fill(color)
                            .frame(width: max(2, candleWidth * 0.8))
                            .position(x: x + candleWidth / 2, y: min(openY, closeY) + abs(openY - closeY) / 2)
                            .frame(height: max(1, abs(openY - closeY)))
                    }
                }
                .frame(width: width, height: height)
            )
        }
        .frame(height: 250)
        .padding(.horizontal, 4)
    }
    
    private var volumeChart: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let count = data.count
            guard count > 0 else { return AnyView(Text("")) }
            
            let maxVolume = data.map { $0.volume }.max() ?? 1
            let barWidth = max(2, width / CGFloat(count) - 1)
            
            return AnyView(
                HStack(spacing: 1) {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                        let isUp = item.close >= item.open
                        let volumeHeight = CGFloat(item.volume) / CGFloat(maxVolume) * height * 0.8
                        Rectangle()
                            .fill(isUp ? Color.jcpRed.opacity(0.5) : Color.jcpGreen.opacity(0.5))
                            .frame(width: barWidth, height: volumeHeight)
                            .alignmentGuide(.bottom) { _ in 0 }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.horizontal, 4)
            )
        }
        .frame(height: 60)
    }
    
    private var statsBar: some View {
        HStack {
            Text("高: \(data.last?.high ?? 0, specifier: "%.2f")")
            Text("低: \(data.last?.low ?? 0, specifier: "%.2f")")
            Text("开: \(data.last?.open ?? 0, specifier: "%.2f")")
            Text("收: \(data.last?.close ?? 0, specifier: "%.2f")")
            Text("量: \((data.last?.volume ?? 0).formatVolume())")
        }
        .font(.caption2)
        .foregroundColor(.jcpTextTertiary)
        .padding(8)
    }
}

// MARK: - 盘口视图
struct OrderBookView: View {
    let orderBook: OrderBook?
    
    var body: some View {
        VStack(spacing: 0) {
            if let book = orderBook {
                // 标题
                HStack {
                    Text("卖五档")
                        .font(.caption)
                        .foregroundColor(.jcpRed)
                    Spacer()
                    Text("盘口深度")
                        .font(.headline)
                        .foregroundColor(.jcpTextPrimary)
                    Spacer()
                    Text("买五档")
                        .font(.caption)
                        .foregroundColor(.jcpGreen)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // 卖盘
                VStack(spacing: 2) {
                    ForEach(Array(book.asks.reversed().enumerated()), id: \.offset) { i, item in
                        orderBookRow(item: item, isBid: false, maxPercent: book.asks.map(\.percent).max() ?? 100)
                    }
                }
                
                // 当前价
                HStack {
                    Text("最新")
                    Spacer()
                    // 这里应该用 stock 的当前价，简化处理
                    Text("--")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.jcpSurface)
                
                // 买盘
                VStack(spacing: 2) {
                    ForEach(Array(book.bids.enumerated()), id: \.offset) { i, item in
                        orderBookRow(item: item, isBid: true, maxPercent: book.bids.map(\.percent).max() ?? 100)
                    }
                }
            } else {
                Spacer()
                Text("暂无盘口数据")
                    .foregroundColor(.jcpTextTertiary)
                Spacer()
            }
        }
        .background(Color.jcpBackground)
    }
    
    private func orderBookRow(item: OrderBookItem, isBid: Bool, maxPercent: Double) -> some View {
        ZStack(alignment: .trailing) {
            Rectangle()
                .fill(isBid ? Color.jcpGreen.opacity(0.1) : Color.jcpRed.opacity(0.1))
                .frame(width: maxPercent > 0 ? CGFloat(item.percent / maxPercent) * UIScreen.main.bounds.width * 0.7 : 0)
                .frame(maxWidth: .infinity, alignment: isBid ? .leading : .trailing)
            
            HStack {
                Text(item.price.formatPrice())
                    .font(.caption)
                    .foregroundColor(.jcpTextPrimary)
                    .frame(width: 80, alignment: isBid ? .leading : .trailing)
                
                Spacer()
                
                Text(item.size.formatVolume())
                    .font(.caption)
                    .foregroundColor(.jcpTextSecondary)
                    .frame(width: 80, alignment: .center)
                
                Spacer()
                
                Text(item.total.formatVolume())
                    .font(.caption)
                    .foregroundColor(.jcpTextTertiary)
                    .frame(width: 80, alignment: isBid ? .trailing : .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }
}

// MARK: - F10 概览
struct F10OverviewView: View {
    let f10Data: F10Overview?
    let isLoading: Bool
    
    var body: some View {
        if isLoading {
            Spacer()
            ProgressView()
            Spacer()
        } else if let f10 = f10Data {
            ScrollView {
                VStack(spacing: 12) {
                    // 公司信息
                    if let company = f10.company {
                        GroupBox("公司信息") {
                            infoRow("公司名称", company.name)
                            if let industry = company.industry {
                                infoRow("所属行业", industry)
                            }
                            if let listingDate = company.listingDate {
                                infoRow("上市日期", listingDate)
                            }
                            if let employees = company.employees {
                                infoRow("员工人数", "\(employees)人")
                            }
                            if let website = company.website {
                                infoRow("公司网站", website)
                            }
                        }
                        .groupBoxStyle(JCPGroupBoxStyle())
                    }
                    
                    // 估值
                    if let valuation = f10.valuation {
                        GroupBox("估值数据") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                if let pe = valuation.peTtm { valuationItem("PE(TTM)", String(format: "%.2f", pe)) }
                                if let pb = valuation.pb { valuationItem("PB", String(format: "%.2f", pb)) }
                                if let turnover = valuation.turnoverRate { valuationItem("换手率", String(format: "%.2f%%", turnover)) }
                                if let cap = valuation.totalMarketCap { valuationItem("总市值", String(format: "%.2f亿", cap / 1_0000_0000)) }
                            }
                            .padding(.vertical, 4)
                        }
                        .groupBoxStyle(JCPGroupBoxStyle())
                    }
                    
                    // 财务数据
                    if let financials = f10.financials, !financials.isEmpty {
                        GroupBox("财务数据") {
                            ScrollView(.horizontal) {
                                VStack(spacing: 0) {
                                    HStack(spacing: 0) {
                                        Text("年份").frame(width: 60, alignment: .leading)
                                        Text("营收").frame(width: 100, alignment: .trailing)
                                        Text("净利润").frame(width: 100, alignment: .trailing)
                                        Text("EPS").frame(width: 70, alignment: .trailing)
                                        Text("ROE").frame(width: 70, alignment: .trailing)
                                    }
                                    .font(.caption)
                                    .foregroundColor(.jcpTextTertiary)
                                    .padding(.vertical, 4)
                                    
                                    Divider()
                                    
                                    ForEach(financials, id: \.year) { fin in
                                        HStack(spacing: 0) {
                                            Text(fin.year).frame(width: 60, alignment: .leading)
                                            Text(fin.revenue?.formatAmount() ?? "-").frame(width: 100, alignment: .trailing)
                                            Text(fin.netProfit?.formatAmount() ?? "-").frame(width: 100, alignment: .trailing)
                                            Text(fin.eps.map { String(format: "%.2f", $0) } ?? "-").frame(width: 70, alignment: .trailing)
                                            Text(fin.roe.map { String(format: "%.1f%%", $0) } ?? "-").frame(width: 70, alignment: .trailing)
                                        }
                                        .font(.caption)
                                        .foregroundColor(.jcpTextPrimary)
                                        .padding(.vertical, 2)
                                    }
                                }
                            }
                        }
                        .groupBoxStyle(JCPGroupBoxStyle())
                    }
                    
                    // 主要指标
                    if let indicators = f10.mainIndicators {
                        GroupBox("主要指标") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(indicators, id: \.name) { indicator in
                                    HStack {
                                        Text(indicator.name)
                                            .font(.caption)
                                            .foregroundColor(.jcpTextSecondary)
                                        Spacer()
                                        Text(indicator.value)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.jcpTextPrimary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .groupBoxStyle(JCPGroupBoxStyle())
                    }
                }
                .padding()
            }
        } else {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundColor(.jcpTextTertiary)
                Text("点击加载 F10 数据")
                    .foregroundColor(.jcpTextSecondary)
            }
            Spacer()
        }
    }
    
    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.jcpTextTertiary)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundColor(.jcpTextPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 2)
    }
    
    private func valuationItem(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.jcpTextTertiary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.jcpTextPrimary)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color.jcpSurface)
        .cornerRadius(6)
    }
}

struct JCPGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            configuration.label
                .font(.headline)
                .foregroundColor(.jcpAccent)
            configuration.content
        }
        .padding()
        .background(Color.jcpCardBackground)
        .cornerRadius(12)
    }
}
