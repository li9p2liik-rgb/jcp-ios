import Foundation

// MARK: - 模拟数据服务
// 提供模拟的股票市场数据，模拟 Go 后端的 API 调用

class MockDataService {
    
    static let shared = MockDataService()
    
    // MARK: - 模拟股票池
    let stockPool: [String: Stock] = [
        "000001": Stock(symbol: "000001", name: "平安银行", price: 11.28, change: 0.32, changePercent: 2.92, volume: 158_234_567, amount: 17_8500_0000, marketCap: "2189亿", sector: "银行", open: 10.96, high: 11.35, low: 10.92, preClose: 10.96),
        "000002": Stock(symbol: "000002", name: "万科A", price: 8.45, change: -0.15, changePercent: -1.74, volume: 89_123_456, amount: 7_5600_0000, marketCap: "1008亿", sector: "房地产", open: 8.60, high: 8.65, low: 8.40, preClose: 8.60),
        "000333": Stock(symbol: "000333", name: "美的集团", price: 65.80, change: 1.20, changePercent: 1.86, volume: 35_678_901, amount: 23_4500_0000, marketCap: "4580亿", sector: "家用电器", open: 64.60, high: 66.20, low: 64.50, preClose: 64.60),
        "000651": Stock(symbol: "000651", name: "格力电器", price: 40.20, change: -0.50, changePercent: -1.23, volume: 42_345_678, amount: 17_0600_0000, marketCap: "2263亿", sector: "家用电器", open: 40.70, high: 40.80, low: 40.10, preClose: 40.70),
        "000725": Stock(symbol: "000725", name: "京东方A", price: 4.28, change: 0.08, changePercent: 1.90, volume: 512_345_678, amount: 21_8900_0000, marketCap: "1640亿", sector: "电子", open: 4.20, high: 4.32, low: 4.18, preClose: 4.20),
        "000858": Stock(symbol: "000858", name: "五粮液", price: 135.60, change: 3.80, changePercent: 2.88, volume: 28_901_234, amount: 38_9000_0000, marketCap: "5263亿", sector: "白酒", open: 131.80, high: 136.50, low: 131.50, preClose: 131.80),
        "002415": Stock(symbol: "002415", name: "海康威视", price: 32.50, change: 0.45, changePercent: 1.40, volume: 45_678_901, amount: 14_8000_0000, marketCap: "3032亿", sector: "计算机", open: 32.05, high: 32.80, low: 32.00, preClose: 32.05),
        "002475": Stock(symbol: "002475", name: "立讯精密", price: 36.80, change: 1.20, changePercent: 3.37, volume: 67_890_123, amount: 24_8000_0000, marketCap: "2635亿", sector: "电子", open: 35.60, high: 37.10, low: 35.50, preClose: 35.60),
        "300059": Stock(symbol: "300059", name: "东方财富", price: 13.20, change: -0.30, changePercent: -2.22, volume: 234_567_890, amount: 31_2000_0000, marketCap: "2090亿", sector: "金融", open: 13.50, high: 13.55, low: 13.10, preClose: 13.50),
        "300750": Stock(symbol: "300750", name: "宁德时代", price: 198.50, change: 5.60, changePercent: 2.90, volume: 34_567_890, amount: 68_5000_0000, marketCap: "8734亿", sector: "电力设备", open: 192.90, high: 199.80, low: 192.50, preClose: 192.90),
        "600519": Stock(symbol: "600519", name: "贵州茅台", price: 1520.00, change: 28.00, changePercent: 1.88, volume: 8_901_234, amount: 135_0000_0000, marketCap: "19095亿", sector: "白酒", open: 1492.00, high: 1528.00, low: 1490.00, preClose: 1492.00),
        "600036": Stock(symbol: "600036", name: "招商银行", price: 34.50, change: 0.60, changePercent: 1.77, volume: 56_789_012, amount: 19_5000_0000, marketCap: "8701亿", sector: "银行", open: 33.90, high: 34.80, low: 33.80, preClose: 33.90),
        "600276": Stock(symbol: "600276", name: "恒瑞医药", price: 42.80, change: 0.90, changePercent: 2.15, volume: 38_901_234, amount: 16_5500_0000, marketCap: "2730亿", sector: "医药", open: 41.90, high: 43.20, low: 41.80, preClose: 41.90),
        "600887": Stock(symbol: "600887", name: "伊利股份", price: 28.60, change: -0.20, changePercent: -0.69, volume: 45_678_901, amount: 13_1000_0000, marketCap: "1820亿", sector: "食品饮料", open: 28.80, high: 28.90, low: 28.40, preClose: 28.80),
        "601318": Stock(symbol: "601318", name: "中国平安", price: 42.30, change: 0.80, changePercent: 1.93, volume: 78_901_234, amount: 33_3000_0000, marketCap: "7710亿", sector: "保险", open: 41.50, high: 42.60, low: 41.40, preClose: 41.50),
        "601398": Stock(symbol: "601398", name: "工商银行", price: 5.86, change: 0.04, changePercent: 0.69, volume: 189_012_345, amount: 11_0700_0000, marketCap: "20883亿", sector: "银行", open: 5.82, high: 5.88, low: 5.80, preClose: 5.82),
        "601857": Stock(symbol: "601857", name: "中国石油", price: 8.95, change: -0.12, changePercent: -1.32, volume: 123_456_789, amount: 11_0500_0000, marketCap: "16378亿", sector: "石油石化", open: 9.07, high: 9.10, low: 8.90, preClose: 9.07),
        "688981": Stock(symbol: "688981", name: "中芯国际", price: 56.80, change: 2.30, changePercent: 4.22, volume: 67_890_123, amount: 38_2000_0000, marketCap: "4499亿", sector: "半导体", open: 54.50, high: 57.20, low: 54.30, preClose: 54.50),
    ]
    
    // MARK: - 大盘指数
    let marketIndices: [MarketIndex] = [
        MarketIndex(code: "000001", name: "上证指数", price: 3128.56, change: 15.78, changePercent: 0.51, volume: 3_456_789_012, amount: 4123_4567_8901.0),
        MarketIndex(code: "399001", name: "深证成指", price: 10523.45, change: 89.23, changePercent: 0.86, volume: 4_567_890_123, amount: 5678_9012_3456.0),
        MarketIndex(code: "399006", name: "创业板指", price: 2135.67, change: 23.45, changePercent: 1.11, volume: 1_234_567_890, amount: 1890_1234_5678.0),
        MarketIndex(code: "688888", name: "科创50", price: 956.78, change: 12.34, changePercent: 1.31, volume: 456_789_012, amount: 678_9012_3456.0),
    ]
    
    // MARK: - 生成 K 线数据
    func generateKLineData(code: String, period: String, days: Int) -> [KLineData] {
        guard let baseStock = stockPool[code] else { return [] }
        let basePrice = baseStock.preClose
        var data: [KLineData] = []
        var currentPrice = basePrice
        
        let calendar = Calendar.current
        let now = Date()
        var date = calendar.date(byAdding: .day, value: -days, to: now)!
        
        for i in 0..<days {
            if calendar.isDateInWeekend(date) {
                date = calendar.date(byAdding: .day, value: 1, to: date)!
                continue
            }
            
            let volatility = Double.random(in: -0.03...0.03)
            let open = currentPrice * (1 + volatility * 0.5)
            let close = open * (1 + volatility)
            let high = max(open, close) * (1 + abs(Double.random(in: 0...0.015)))
            let low = min(open, close) * (1 - abs(Double.random(in: 0...0.015)))
            let volume = Int64.random(in: 10_000_000...200_000_000)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let timeStr = formatter.string(from: date)
            
            data.append(KLineData(time: timeStr, open: open, high: high, low: low, close: close, volume: volume,
                                  ma5: nil, ma10: nil, ma20: nil))
            
            currentPrice = close
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        
        // 计算均线
        for i in 0..<data.count {
            if i >= 4 {
                let ma5 = (0...4).reduce(0.0) { $0 + data[i - $1].close } / 5.0
                data[i].ma5 = ma5
            }
            if i >= 9 {
                let ma10 = (0...9).reduce(0.0) { $0 + data[i - $1].close } / 10.0
                data[i].ma10 = ma10
            }
            if i >= 19 {
                let ma20 = (0...19).reduce(0.0) { $0 + data[i - $1].close } / 20.0
                data[i].ma20 = ma20
            }
        }
        
        return data
    }
    
    // MARK: - 生成盘口数据
    func generateOrderBook(code: String) -> OrderBook {
        guard let stock = stockPool[code] else {
            return OrderBook(bids: [], asks: [])
        }
        
        let price = stock.price
        var bids: [OrderBookItem] = []
        var asks: [OrderBookItem] = []
        var totalBid: Int64 = 0
        var totalAsk: Int64 = 0
        
        for i in 1...5 {
            let bidPrice = price - Double(i) * 0.01
            let bidSize = Int64.random(in: 1000...50000)
            totalBid += bidSize
            let askPrice = price + Double(i) * 0.01
            let askSize = Int64.random(in: 1000...50000)
            totalAsk += askSize
            bids.append(OrderBookItem(price: bidPrice, size: bidSize, total: totalBid, percent: 0))
            asks.append(OrderBookItem(price: askPrice, size: askSize, total: totalAsk, percent: 0))
        }
        
        // 计算百分比
        let maxTotal = max(totalBid, totalAsk)
        if maxTotal > 0 {
            for i in 0..<5 {
                bids[i] = OrderBookItem(price: bids[i].price, size: bids[i].size, total: bids[i].total, percent: Double(bids[i].total) / Double(maxTotal) * 100)
                asks[i] = OrderBookItem(price: asks[i].price, size: asks[i].size, total: asks[i].total, percent: Double(asks[i].total) / Double(maxTotal) * 100)
            }
        }
        
        return OrderBook(bids: bids, asks: asks)
    }
    
    // MARK: - 搜索股票
    func searchStocks(keyword: String) -> [Stock] {
        if keyword.isEmpty { return [] }
        return stockPool.values.filter {
            $0.symbol.contains(keyword) || $0.name.contains(keyword)
        }
    }
    
    // MARK: - 热点数据
    func generateHotTrends(platform: String) -> [HotTrendItem] {
        let trends: [String: [String]] = [
            "baidu": ["A股三大指数集体上涨", "新能源板块持续走强", "央行最新货币政策解读", "华为发布新一代芯片", "人民币汇率波动分析", "2024年GDP增长目标", "人工智能概念股爆发", "房地产市场新政出台", "新能源汽车销量创新高", "半导体产业链投资机会"],
            "weibo": ["今日股市行情分析", "北向资金净流入超百亿", "创业板指数突破新高", "白酒板块回暖", "医药股集体拉升", "科技股领涨两市", "大宗商品价格走势", "量化交易监管新规", "ETF基金规模创新高", "散户投资者情绪指数"],
            "douyin": ["炒股入门必看技巧", "今日涨停板复盘", "K线形态识别教学", "主力资金流向分析", "短线交易策略分享", "价值投资长期持有", "技术指标MACD详解", "选股逻辑与方法", "仓位管理技巧", "止盈止损策略"],
        ]
        
        let platformTrends = trends[platform] ?? trends["baidu"]!
        return platformTrends.enumerated().map { i, title in
            HotTrendItem(id: "\(platform)-\(i)", title: title, hot: Int.random(in: 100000...9999999), url: nil, rank: i + 1)
        }
    }
    
    // MARK: - 龙虎榜数据
    func generateLongHuBang() -> [LongHuBangItem] {
        let stocks = Array(stockPool.values.shuffled().prefix(10))
        return stocks.map { stock in
            let totalBuy = Double.random(in: 1000_0000...50000_0000)
            let totalSell = Double.random(in: 1000_0000...50000_0000)
            return LongHuBangItem(
                symbol: stock.symbol,
                name: stock.name,
                typeName: ["日涨幅偏离值达7%", "连续三日涨幅偏离值达20%", "日换手率达20%", "日振幅达15%"].randomElement()!,
                reason: "当日涨幅偏离值达7%的证券",
                totalBuy: totalBuy,
                totalSell: totalSell,
                netAmount: totalBuy - totalSell
            )
        }
    }
    
    // MARK: - F10 数据
    func generateF10Data(code: String) -> F10Overview {
        guard let stock = stockPool[code] else {
            return F10Overview(code: code, company: nil, valuation: nil, mainIndicators: nil, financials: nil, errors: ["error": "股票不存在"])
        }
        
        let company = F10Company(
            name: stock.name,
            englishName: "\(stock.name) Co., Ltd.",
            listingDate: "2010-01-15",
            legalRepresentative: "张三",
            registeredCapital: "100亿",
            employees: Int.random(in: 1000...50000),
            businessScope: "技术开发、技术咨询、技术服务；销售自行开发的产品；货物进出口、技术进出口、代理进出口。",
            industry: stock.sector,
            website: "www.\(stock.name).com",
            address: "北京市朝阳区"
        )
        
        let valuation = StockValuation(
            price: stock.price,
            peTtm: Double.random(in: 10...50),
            pb: Double.random(in: 1...10),
            totalMarketCap: Double.random(in: 100_0000_0000...10000_0000_0000),
            floatMarketCap: Double.random(in: 50_0000_0000...5000_0000_0000),
            turnoverRate: Double.random(in: 0.5...5.0)
        )
        
        let indicators = [
            F10MainIndicator(name: "每股收益", value: String(format: "%.2f", Double.random(in: 0.1...5)), change: nil),
            F10MainIndicator(name: "每股净资产", value: String(format: "%.2f", Double.random(in: 1...30)), change: nil),
            F10MainIndicator(name: "净资产收益率", value: String(format: "%.1f%%", Double.random(in: 5...30)), change: nil),
            F10MainIndicator(name: "毛利率", value: String(format: "%.1f%%", Double.random(in: 20...80)), change: nil),
            F10MainIndicator(name: "净利润增长率", value: String(format: "%.1f%%", Double.random(in: -20...50)), change: nil),
            F10MainIndicator(name: "资产负债率", value: String(format: "%.1f%%", Double.random(in: 20...80)), change: nil),
        ]
        
        let financials = (0..<5).map { i in
            let year = "\(2025 - i)"
            return F10FinancialData(
                year: year,
                revenue: Double.random(in: 50_0000_0000...5000_0000_0000),
                netProfit: Double.random(in: 5_0000_0000...500_0000_0000),
                eps: Double.random(in: 0.3...5),
                bvps: Double.random(in: 3...30),
                roe: Double.random(in: 8...30),
                grossMargin: Double.random(in: 25...70)
            )
        }
        
        return F10Overview(code: code, company: company, valuation: valuation, mainIndicators: indicators, financials: financials)
    }
}
