import Foundation
import Combine

// MARK: - 自选股 ViewModel
class WatchlistViewModel: ObservableObject {
    
    @Published var stocks: [Stock] = []
    @Published var marketIndices: [MarketIndex] = []
    @Published var marketStatus: MarketStatusInfo?
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var searchResults: [Stock] = []
    @Published var isSearching = false
    
    private var cancellables = Set<AnyCancellable>()
    private let configService = ConfigService.shared
    private let mockService = MockDataService.shared
    
    init() {
        loadData()
        
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] text in
                self?.searchStocks(keyword: text)
            }
            .store(in: &cancellables)
    }
    
    func loadData() {
        isLoading = true
        
        // Fetch real market indices
        MarketDataService.shared.fetchMarketIndices { [weak self] indices in
            self?.marketIndices = indices
        }
        
        // Start with cached stocks, then refresh with real data
        stocks = configService.getWatchlistStocks()
        let codes = stocks.map { $0.symbol }
        MarketDataService.shared.fetchRealTimeData(codes: codes) { [weak self] realStocks in
            self?.stocks = realStocks
            self?.isLoading = false
        }
        
        marketStatus = MarketStatusInfo(
            status: .trading,
            statusText: "Trading",
            isTradeDay: true,
            holidayName: nil
        )
    }
    
    func refresh() {
        loadData()
    }
    
    func removeStock(symbol: String) {
        configService.removeFromWatchlist(symbol: symbol)
        stocks = configService.getWatchlistStocks()
    }
    
    func addStock(symbol: String) {
        configService.addToWatchlist(symbol: symbol)
        stocks = configService.getWatchlistStocks()
    }
    
    func isInWatchlist(symbol: String) -> Bool {
        configService.isInWatchlist(symbol: symbol)
    }
    
    private func searchStocks(keyword: String) {
        if keyword.isEmpty {
            searchResults = []
            isSearching = false
            return
        }
        isSearching = true
        searchResults = mockService.searchStocks(keyword: keyword)
    }
}

// MARK: - Stock Detail ViewModel (Real API)
class StockDetailViewModel: ObservableObject {
    @Published var stock: Stock?
    @Published var kLineData: [KLineData] = []
    @Published var orderBook: OrderBook?
    @Published var f10Data: F10Overview?
    @Published var valuation: StockValuation?
    @Published var selectedPeriod = "1d"
    @Published var isLoadingKLine = false
    @Published var isLoadingF10 = false
    @Published var showF10 = false
    @Published var position: StockPosition?
    @Published var researchReports: [ResearchReport] = []

    private let mockService = MockDataService.shared
    private let api = RealAPIService.shared

    func loadStock(code: String) {
        stock = mockService.stockPool[code]
        loadKLineData(code: code)
        loadOrderBook(code: code)
    }

    func loadRealTimeStock(code: String) {
        MarketDataService.shared.fetchRealTimeData(codes: [code]) { [weak self] stocks in
            if let s = stocks.first { self?.stock = s }
        }
    }

    func loadKLineData(code: String) {
        isLoadingKLine = true
        let days = periodToDays(selectedPeriod)
        MarketDataService.shared.fetchKLineData(code: code, period: selectedPeriod, days: days) { [weak self] data in
            self?.kLineData = data
            self?.isLoadingKLine = false
        }
    }

    func loadOrderBook(code: String) {
        api.fetchOrderBook(code: code) { [weak self] book in
            self?.orderBook = book ?? MockDataService.shared.generateOrderBook(code: code)
        }
    }

    func loadF10Data(code: String) {
        isLoadingF10 = true
        api.fetchF10Overview(code: code) { [weak self] overview in
            self?.f10Data = overview
            self?.api.fetchValuation(code: code) { val in
                if var f10 = self?.f10Data {
                    f10.valuation = val
                    self?.f10Data = f10
                }
                self?.isLoadingF10 = false
                self?.showF10 = true
            }
        }
    }

    func loadResearchReports(code: String) {
        api.fetchResearchReports(code: code) { [weak self] reports in
            self?.researchReports = reports
        }
    }

    private func periodToDays(_ period: String) -> Int {
        switch period {
        case "1m": return 1
        case "5m": return 5
        case "1d": return 60
        case "1w": return 120
        case "1mo": return 250
        default: return 60
        }
    }
}// MARK: - AI 智库 ViewModel
class AgentRoomViewModel: ObservableObject {
    
    @Published var messages: [ChatMessage] = []
    @Published var isAnalyzing = false
    @Published var selectedAgents: [Agent] = []
    @Published var availableAgents: [Agent] = Constants.defaultAgents
    @Published var currentStock: Stock?
    @Published var queryText = ""
    @Published var showAgentSelection = false
    @Published var analysisProgress = 0.0
    
    private var cancellables = Set<AnyCancellable>()
    private let aiService = AIAgentService.shared
    private let mockService = MockDataService.shared
    
    func setStock(_ stock: Stock) {
        currentStock = stock
    }
    
    func startAnalysis() {
        guard let stock = currentStock, !selectedAgents.isEmpty else { return }
        guard !isAnalyzing else { return }
        
        isAnalyzing = true
        analysisProgress = 0
        messages.removeAll()
        
        // 添加开场白
        let opening = ChatMessage(
            agentId: "system",
            agentName: "系统",
            content: "## 开始分析 \(stock.name)(\(stock.symbol))\n\n**当前价格:** \(stock.price)元  |  **涨跌幅:** \(stock.changePercent.formatPercent())\n\n邀请以下专家进行多维度分析：\n\(selectedAgents.map { "- \($0.name)（\($0.role.rawValue)）" }.joined(separator: "\n"))",
            msgType: .opening,
            round: 1
        )
        messages.append(opening)
        
        // 逐个获取 Agent 分析
        let totalAgents = selectedAgents.count
        for (index, agent) in selectedAgents.enumerated() {
            let context = buildContext(stock: stock)
            
            aiService.generateAgentResponse(agent: agent, stock: stock, query: queryText, context: context)
                .sink { [weak self] message in
                    guard let self = self else { return }
                    self.messages.append(message)
                    self.analysisProgress = Double(index + 1) / Double(totalAgents)
                    
                    // 最后一个 Agent 完成后生成摘要
                    if index == totalAgents - 1 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.generateSummary()
                        }
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    private func generateSummary() {
        guard let stock = currentStock else { return }
        
        aiService.generateSummary(messages: messages, stock: stock)
            .sink { [weak self] summary in
                self?.messages.append(summary)
                self?.isAnalyzing = false
                self?.analysisProgress = 1.0
            }
            .store(in: &cancellables)
    }
    
    private func buildContext(stock: Stock) -> String {
        var ctx = """
        Stock: \(stock.name) (\(stock.symbol))
        Price: \(stock.price)
        Change: \(stock.changePercent.formatPercent())
        Open: \(stock.open)  High: \(stock.high)  Low: \(stock.low)  PreClose: \(stock.preClose)
        Volume: \(stock.volume.formatVolume())  Amount: \(stock.amount.formatAmount())
        Sector: \(stock.sector)  Market Cap: \(stock.marketCap)
        
        User Question: \(queryText.isEmpty ? "Please analyze this stock comprehensively" : queryText)
        """
        
        // Add F10 data if available
        let f10 = MockDataService.shared.generateF10Data(code: stock.symbol)
        if let v = f10.valuation {
            ctx += "\n\nValuation: PE(TTM)=\(v.peTtm?.description ?? "N/A"), PB=\(v.pb?.description ?? "N/A"), TurnoverRate=\(v.turnoverRate?.description ?? "N/A")%"
        }
        
        return ctx
    }
    
    func toggleAgent(_ agent: Agent) {
        if let index = selectedAgents.firstIndex(where: { $0.id == agent.id }) {
            selectedAgents.remove(at: index)
        } else {
            selectedAgents.append(agent)
        }
    }
    
    func isAgentSelected(_ agent: Agent) -> Bool {
        selectedAgents.contains(where: { $0.id == agent.id })
    }
    
    func clearMessages() {
        messages.removeAll()
    }
}

// MARK: - Market ViewModel (Real API)
class MarketViewModel: ObservableObject {
    @Published var marketIndices: [MarketIndex] = []
    @Published var hotTrends: [HotTrendResult] = []
    @Published var longHuBangItems: [LongHuBangItem] = []
    @Published var marketMoves: [StockMove] = []
    @Published var boardFundFlows: [BoardFundFlow] = []
    @Published var telegraphs: [Telegraph] = []
    @Published var researchReports: [ResearchReport] = []
    @Published var selectedPlatform = "weibo"
    @Published var isLoadingTrends = false
    @Published var isLoadingLHB = false
    @Published var isLoadingMoves = false
    @Published var isLoadingFundFlow = false

    private let api = RealAPIService.shared

    func loadAllData() {
        loadMarketIndices()
        loadHotTrends()
        loadTelegraphs()
    }

    func loadMarketIndices() {
        MarketDataService.shared.fetchMarketIndices { [weak self] indices in
            self?.marketIndices = indices
        }
    }

    func loadHotTrends() {
        isLoadingTrends = true
        let platforms = Constants.hotTrendPlatforms.map { $0.id }
        let group = DispatchGroup()
        var results: [HotTrendResult] = []

        for platform in platforms {
            group.enter()
            api.fetchHotTrend(platform: platform) { [weak self] result in
                let name = Constants.hotTrendPlatforms.first { $0.id == platform }?.name ?? platform
                if let r = result {
                    results.append(HotTrendResult(platform: platform, platformName: name, items: r.items, lastUpdated: Date()))
                } else {
                    // Fallback to mock
                    results.append(HotTrendResult(platform: platform, platformName: name,
                        items: MockDataService.shared.generateHotTrends(platform: platform), lastUpdated: Date()))
                }
                group.leave()
            }
        }
        group.notify(queue: .main) { [weak self] in
            self?.hotTrends = results
            self?.isLoadingTrends = false
        }
    }

    func loadLongHuBang() {
        isLoadingLHB = true
        api.fetchLongHuBang(pageSize: 20, pageNumber: 1) { [weak self] items in
            self?.longHuBangItems = items.isEmpty ? MockDataService.shared.generateLongHuBang() : items
            self?.isLoadingLHB = false
        }
    }

    func loadMarketMoves() {
        isLoadingMoves = true
        api.fetchStockMoves(moveType: "all") { [weak self] items in
            self?.marketMoves = items
            self?.isLoadingMoves = false
        }
    }

    func loadBoardFundFlow() {
        isLoadingFundFlow = true
        api.fetchBoardFundFlow(category: "all") { [weak self] items in
            self?.boardFundFlows = items
            self?.isLoadingFundFlow = false
        }
    }

    func loadTelegraphs() {
        api.fetchTelegraphs { [weak self] items in
            self?.telegraphs = items
        }
    }

    func loadResearchReports(code: String) {
        api.fetchResearchReports(code: code) { [weak self] items in
            self?.researchReports = items
        }
    }
}// MARK: - 设置 ViewModel
class SettingsViewModel: ObservableObject {
    
    @Published var aiConfigs: [AIConfig] = []
    @Published var showAddConfig = false
    @Published var editingConfig: AIConfig?
    @Published var alertMessage = ""
    @Published var showAlert = false
    
    private let configService = ConfigService.shared
    
    init() {
        loadConfigs()
    }
    
    func loadConfigs() {
        aiConfigs = configService.config.aiConfigs
    }
    
    func saveConfig(_ config: AIConfig) {
        configService.saveAIConfig(config)
        loadConfigs()
    }
    
    func deleteConfig(id: String) {
        configService.deleteAIConfig(id: id)
        loadConfigs()
    }
    
    var defaultConfig: AIConfig? {
        aiConfigs.first { $0.id == configService.config.defaultAIId }
    }
}
