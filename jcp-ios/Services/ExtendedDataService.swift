import Foundation

extension MockDataService {

    func generateTelegraphs() -> [Telegraph] {
        let items: [(String, String, String)] = [
            ("14:30", "MLF rate cut 10bp to 2.5%, releasing liquidity signal", ""),
            ("14:15", "North-bound funds net buy over 8B yuan, 5-day inflow streak", ""),
            ("13:45", "MIIT releases new energy vehicle development plan", ""),
            ("13:20", "Shanghai/Shenzhen volume breaks 800B, semiconductor leads", ""),
            ("11:30", "A-shares close morning session higher, 3500+ stocks rise", ""),
            ("10:45", "Huawei unveils next-gen AI chip, concept stocks surge", ""),
            ("10:20", "SASAC pushes listed SOEs to improve quality and repurchase", ""),
            ("09:45", "CNY central parity rate strengthened by 200 basis points", ""),
            ("09:30", "Markets open mixed, new energy sector extends gains", ""),
            ("09:00", "CSRC releases quantitative trading regulation rules", "")
        ]
        return items.map { Telegraph(time: $0.0, content: $0.1, url: $0.2) }
    }

    func generateResearchReports() -> [ResearchReport] {
        [
            ResearchReport(id: "1", title: "Tech Industry 2025 Strategy", orgName: "CITIC Securities", rating: "Outperform", publishDate: "2026-07-15", stockCode: "", stockName: ""),
            ResearchReport(id: "2", title: "New Energy Supply Chain Deep Dive", orgName: "Huatai Securities", rating: "Buy", publishDate: "2026-07-18", stockCode: "", stockName: ""),
            ResearchReport(id: "3", title: "Liquor Sector Quarterly Preview", orgName: "GTJA", rating: "Accumulate", publishDate: "2026-07-19", stockCode: "", stockName: ""),
            ResearchReport(id: "4", title: "Semiconductor Equipment Localization", orgName: "Haitong Securities", rating: "Buy", publishDate: "2026-07-17", stockCode: "", stockName: ""),
            ResearchReport(id: "5", title: "Pharma Monthly Tracking Report", orgName: "GF Securities", rating: "Neutral", publishDate: "2026-07-14", stockCode: "", stockName: "")
        ]
    }

    func generateDefaultStrategy() -> StrategyData {
        StrategyData(
            id: "default",
            name: "Default Strategy",
            description: "Multi-agent collaborative analysis strategy",
            aiConfigID: "",
            agents: [
                StrategyAgent(id: "bull-1", name: "Bull Analyst", role: "Bull", avatar: "chart.line.uptrend.xyaxis", color: "#ef4444", instruction: "Focus on upside potential and positive catalysts.", tools: ["stock_quote", "kline_data"], mcpServers: [], enabled: true),
                StrategyAgent(id: "bear-1", name: "Risk Sentinel", role: "Bear", avatar: "chart.line.downtrend.xyaxis", color: "#22c55e", instruction: "Identify risks and vulnerabilities.", tools: ["stock_quote", "f10_data"], mcpServers: [], enabled: true),
                StrategyAgent(id: "quant-1", name: "Quant Pioneer", role: "Quant", avatar: "function", color: "#3b82f6", instruction: "Evaluate technical indicators and patterns.", tools: ["kline_data", "order_book"], mcpServers: [], enabled: true),
                StrategyAgent(id: "macro-1", name: "Macro View", role: "Macro", avatar: "building.columns", color: "#f59e0b", instruction: "Analyze policy, industry cycles, and global trends.", tools: ["market_status"], mcpServers: [], enabled: true),
                StrategyAgent(id: "news-1", name: "Intel Hunter", role: "Intel", avatar: "newspaper", color: "#8b5cf6", instruction: "Collect and interpret news and sentiment.", tools: ["news_search", "hot_trends"], mcpServers: [], enabled: true)
            ],
            isActive: true,
            prompts: ["Analyze the stock", "Identify risks", "Give investment advice"],
            systemPrompt: "You are part of an AI think tank analyzing Chinese A-shares."
        )
    }

    func generateFullF10Data(code: String) -> F10Overview {
        guard let stock = stockPool[code] else {
            return F10Overview(code: code, company: nil, valuation: nil, mainIndicators: nil, financials: nil, errors: ["error": "Stock not found"])
        }

        let company = F10Company(
            name: stock.name, englishName: nil, listingDate: "2010-01-15",
            legalRepresentative: nil, registeredCapital: nil, employees: Int.random(in: 1000...100000),
            businessScope: nil, industry: stock.sector, website: nil, address: nil
        )

        let valuation = StockValuation(
            price: stock.price, peTtm: Double.random(in: 8...60), pb: Double.random(in: 1...12),
            totalMarketCap: Double.random(in: 5000000000...200000000000),
            floatMarketCap: Double.random(in: 3000000000...80000000000),
            turnoverRate: Double.random(in: 0.3...8.0), amplitude: nil, totalShares: nil, floatShares: nil
        )

        let indicators = [
            F10MainIndicator(name: "EPS", value: String(format: "%.2f", Double.random(in: 0.1...8)), change: nil),
            F10MainIndicator(name: "NAV/Share", value: String(format: "%.2f", Double.random(in: 2...50)), change: nil),
            F10MainIndicator(name: "ROE", value: String(format: "%.1f%%", Double.random(in: 3...35)), change: nil),
            F10MainIndicator(name: "Gross Margin", value: String(format: "%.1f%%", Double.random(in: 15...85)), change: nil),
            F10MainIndicator(name: "Net Profit Growth", value: String(format: "%.1f%%", Double.random(in: -30...80)), change: nil),
            F10MainIndicator(name: "Debt Ratio", value: String(format: "%.1f%%", Double.random(in: 15...80)), change: nil),
            F10MainIndicator(name: "Op Cash Flow", value: String(format: "%.2fB", Double.random(in: 0.1...20)), change: nil),
            F10MainIndicator(name: "Dividend Yield", value: String(format: "%.2f%%", Double.random(in: 0...5)), change: nil)
        ]

        let financials = (0..<5).map { i in
            F10FinancialData(
                year: "\(2026 - i)", revenue: Double.random(in: 1000000000...500000000000),
                netProfit: Double.random(in: 100000000...80000000000), eps: Double.random(in: 0.2...8),
                bvps: Double.random(in: 3...50), roe: Double.random(in: 5...35), grossMargin: Double.random(in: 20...80)
            )
        }

        return F10Overview(code: code, company: company, valuation: valuation, mainIndicators: indicators, financials: financials, errors: nil)
    }

    func generateMemoryStats(code: String) -> MemoryStats {
        MemoryStats(
            stockCode: code, totalRounds: Int.random(in: 5...50), keyFactsCount: Int.random(in: 3...30),
            lastSummary: "Agents analyzed \(code). Overall cautiously optimistic with focus on sector trends and fundamentals.",
            lastUpdated: Calendar.current.date(byAdding: .day, value: Int.random(in: -7...0), to: Date())!
        )
    }
}

struct MemoryStats: Codable {
    let stockCode: String
    let totalRounds: Int
    let keyFactsCount: Int
    let lastSummary: String
    let lastUpdated: Date
}
