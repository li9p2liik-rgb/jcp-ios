import Foundation

// MARK: - Extended mock data supplement
extension MockDataService {

    // Telegraph / News
    func generateTelegraphs() -> [Telegraph] {
        let items = [
            ("14:30", "????MLF??10????2.5% ???????", ""),
            ("14:15", "??????????80?? ??5????", ""),
            ("13:45", "???????????????? ???????", ""),
            ("13:20", "?????????8000? ???????", ""),
            ("11:30", "A??????????? ?3500?????", ""),
            ("10:45", "???????AI?? ???????", ""),
            ("10:20", "??????????????? ??????", ""),
            ("09:45", "???????????200???", ""),
            ("09:30", "???????? ?????????", ""),
            ("09:00", "????????????? ????????")
        ]
        return items.map { Telegraph(time: $0.0, content: $0.1, url: $0.2) }
    }

    // Research Reports
    func generateResearchReports() -> [ResearchReport] {
        return [
            ResearchReport(id: "1", title: "????2025??????", orgName: "????", rating: "????", publishDate: "2026-07-15", stockCode: "", stockName: ""),
            ResearchReport(id: "2", title: "????????????", orgName: "????", rating: "??", publishDate: "2026-07-18", stockCode: "", stockName: ""),
            ResearchReport(id: "3", title: "??????????", orgName: "????", rating: "??", publishDate: "2026-07-19", stockCode: "", stockName: ""),
            ResearchReport(id: "4", title: "????????????", orgName: "????", rating: "??", publishDate: "2026-07-17", stockCode: "", stockName: ""),
            ResearchReport(id: "5", title: "????????????", orgName: "????", rating: "??", publishDate: "2026-07-14", stockCode: "", stockName: "")
        ]
    }

    // Strategy data
    func generateDefaultStrategy() -> StrategyData {
        StrategyData(
            id: "default",
            name: "Default Strategy",
            description: "Multi-agent collaborative analysis strategy",
            aiConfigID: "",
            agents: [
                StrategyAgent(id: "bull-1", name: "Bull Analyst", role: "?????", avatar: "chart.line.uptrend.xyaxis", color: "#ef4444", instruction: "As a senior bull analyst, focus on upside potential and positive catalysts.", tools: ["stock_quote", "kline_data"], mcpServers: [], enabled: true),
                StrategyAgent(id: "bear-1", name: "Risk Sentinel", role: "?????", avatar: "chart.line.downtrend.xyaxis", color: "#22c55e", instruction: "As a cautious bear, identify risks and vulnerabilities.", tools: ["stock_quote", "f10_data"], mcpServers: [], enabled: true),
                StrategyAgent(id: "quant-1", name: "Quant Pioneer", role: "?????", avatar: "function", color: "#3b82f6", instruction: "As a quantitative analyst, evaluate technical indicators and patterns.", tools: ["kline_data", "order_book"], mcpServers: [], enabled: true),
                StrategyAgent(id: "macro-1", name: "Macro View", role: "?????", avatar: "building.columns", color: "#f59e0b", instruction: "As a macro economist, analyze policy, industry cycles, and global trends.", tools: ["market_status"], mcpServers: [], enabled: true),
                StrategyAgent(id: "news-1", name: "Intel Hunter", role: "?????", avatar: "newspaper", color: "#8b5cf6", instruction: "As a market intelligence analyst, collect and interpret news and sentiment.", tools: ["news_search", "hot_trends"], mcpServers: [], enabled: true)
            ],
            isActive: true,
            prompts: ["Analyze the stock", "Identify risks", "Give investment advice"],
            systemPrompt: "You are part of an AI think tank analyzing Chinese A-shares."
        )
    }

    // Extended F10 with more sections
    func generateFullF10Data(code: String) -> F10Overview {
        guard let stock = stockPool[code] else {
            return F10Overview(code: code, company: nil, valuation: nil, mainIndicators: nil, financials: nil, errors: ["error": "Stock not found"])
        }

        let company = F10Company(
            name: stock.name,
            englishName: "\(stock.name) Co., Ltd.",
            listingDate: "2010-01-15",
            legalRepresentative: "Legal Rep",
            registeredCapital: "10B",
            employees: Int.random(in: 1000...100000),
            businessScope: "Technology development, consulting, services; import/export of goods and technology.",
            industry: stock.sector,
            website: "www.\(stock.name).com",
            address: "Beijing, China"
        )

        let valuation = StockValuation(
            price: stock.price,
            peTtm: Double.random(in: 8...60),
            pb: Double.random(in: 1...12),
            totalMarketCap: Double.random(in: 50_0000_0000...20000_0000_0000),
            floatMarketCap: Double.random(in: 30_0000_0000...8000_0000_0000),
            turnoverRate: Double.random(in: 0.3...8.0),
            amplitude: Double.random(in: 1...10),
            totalShares: Double.random(in: 1_0000_0000...500_0000_0000),
            floatShares: Double.random(in: 5000_0000...300_0000_0000)
        )

        let indicators = [
            F10MainIndicator(name: "EPS", value: String(format: "%.2f", Double.random(in: 0.1...8)), change: nil),
            F10MainIndicator(name: "NAV per Share", value: String(format: "%.2f", Double.random(in: 2...50)), change: nil),
            F10MainIndicator(name: "ROE", value: String(format: "%.1f%%", Double.random(in: 3...35)), change: nil),
            F10MainIndicator(name: "Gross Margin", value: String(format: "%.1f%%", Double.random(in: 15...85)), change: nil),
            F10MainIndicator(name: "Net Profit Growth", value: String(format: "%.1f%%", Double.random(in: -30...80)), change: nil),
            F10MainIndicator(name: "Debt Ratio", value: String(format: "%.1f%%", Double.random(in: 15...80)), change: nil),
            F10MainIndicator(name: "Operating Cash Flow", value: String(format: "%.2f", Double.random(in: 1...200) * 1_0000_0000), change: nil),
            F10MainIndicator(name: "Dividend Yield", value: String(format: "%.2f%%", Double.random(in: 0...5)), change: nil)
        ]

        let financials = (0..<5).map { i in
            F10FinancialData(
                year: "\(2026 - i)",
                revenue: Double.random(in: 10_0000_0000...5000_0000_0000),
                netProfit: Double.random(in: 1_0000_0000...800_0000_0000),
                eps: Double.random(in: 0.2...8),
                bvps: Double.random(in: 3...50),
                roe: Double.random(in: 5...35),
                grossMargin: Double.random(in: 20...80)
            )
        }

        return F10Overview(code: code, company: company, valuation: valuation, mainIndicators: indicators, financials: financials, errors: nil)
    }

    // Memory stats for display
    func generateMemoryStats(code: String) -> MemoryStats {
        MemoryStats(
            stockCode: code,
            totalRounds: Int.random(in: 5...50),
            keyFactsCount: Int.random(in: 3...30),
            lastSummary: "Last discussion: Various agents analyzed \(code). Overall sentiment was cautiously optimistic with key focus on sector trends and fundamentals.",
            lastUpdated: Calendar.current.date(byAdding: .day, value: Int.random(in: -7...0), to: Date())!
        )
    }
}

// MARK: - Memory Stats Model
struct MemoryStats: Codable {
    let stockCode: String
    let totalRounds: Int
    let keyFactsCount: Int
    let lastSummary: String
    let lastUpdated: Date
}
