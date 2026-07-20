import Foundation

// MARK: - Market Data Provider Protocol

protocol MarketDataProvider {
    func searchStocks(query: String) async throws -> [Stock]
    func fetchRealtime(symbol: String) async throws -> Stock
    func fetchKLine(symbol: String, period: TimePeriod, limit: Int) async throws -> [KLineData]
    func fetchIndices() async throws -> [MarketIndex]
    func fetchMarketStatus() async throws -> MarketStatus
    func fetchOrderBook(symbol: String) async throws -> OrderBook
}

// MARK: - Market Service

@MainActor
final class MarketService: ObservableObject {
    static let shared = MarketService()

    private let provider: MarketDataProvider

    @Published var searchResults: [Stock] = []
    @Published var currentStock: Stock?
    @Published var klineData: [KLineData] = []
    @Published var indices: [MarketIndex] = []
    @Published var marketStatus: MarketStatus?
    @Published var orderBook: OrderBook?
    @Published var isLoading = false
    @Published var errorMessage: String?

    init(provider: MarketDataProvider? = nil) {
        self.provider = provider ?? SinaMarketDataProvider()
    }

    func search(_ query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            searchResults = try await provider.searchStocks(query: query)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectStock(_ stock: Stock) async {
        currentStock = stock
        await refreshRealtime(symbol: stock.symbol)
        await refreshKLine(symbol: stock.symbol)
        await refreshOrderBook(symbol: stock.symbol)
    }

    func refreshRealtime(symbol: String) async {
        do {
            currentStock = try await provider.fetchRealtime(symbol: symbol)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshKLine(symbol: String, period: TimePeriod = .day1) async {
        isLoading = true
        defer { isLoading = false }
        do {
            klineData = try await provider.fetchKLine(symbol: symbol, period: period, limit: 200)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshIndices() async {
        do {
            indices = try await provider.fetchIndices()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshMarketStatus() async {
        do {
            marketStatus = try await provider.fetchMarketStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshOrderBook(symbol: String) async {
        do {
            orderBook = try await provider.fetchOrderBook(symbol: symbol)
        } catch {
            // Order book is best-effort
        }
    }
}
