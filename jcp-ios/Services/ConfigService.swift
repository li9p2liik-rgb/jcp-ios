import Foundation
import Combine

class ConfigService: ObservableObject {
    
    static let shared = ConfigService()
    
    @Published var config: AppConfig {
        didSet { saveConfig() }
    }
    
    @Published var watchlistSymbols: [String] {
        didSet { saveWatchlist() }
    }
    
    @Published var activeStrategyId: String = "default"
    
    private init() {
        // 加载配置
        if let data = UserDefaults.standard.data(forKey: "app_config"),
           let config = try? JSONDecoder().decode(AppConfig.self, from: data) {
            self.config = config
        } else {
            self.config = AppConfig(
                aiConfigs: [],
                defaultAIId: "",
                theme: "dark",
                watchlist: Constants.defaultWatchlist
            )
        }
        
        if let symbols = UserDefaults.standard.stringArray(forKey: "watchlist_symbols") {
            self.watchlistSymbols = symbols
        } else {
            self.watchlistSymbols = Constants.defaultWatchlist
        }
    }
    
    func getWatchlistStocks() -> [Stock] {
        return watchlistSymbols.compactMap { symbol in
            MockDataService.shared.stockPool[symbol]
        }
    }
    
    func addToWatchlist(symbol: String) {
        guard !watchlistSymbols.contains(symbol) else { return }
        watchlistSymbols.append(symbol)
    }
    
    func removeFromWatchlist(symbol: String) {
        watchlistSymbols.removeAll { $0 == symbol }
    }
    
    func isInWatchlist(symbol: String) -> Bool {
        watchlistSymbols.contains(symbol)
    }
    
    func saveAIConfig(_ aiConfig: AIConfig) {
        if let index = config.aiConfigs.firstIndex(where: { $0.id == aiConfig.id }) {
            config.aiConfigs[index] = aiConfig
        } else {
            config.aiConfigs.append(aiConfig)
        }
        if config.aiConfigs.count == 1 {
            config.defaultAIId = aiConfig.id
        }
    }
    
    func deleteAIConfig(id: String) {
        config.aiConfigs.removeAll { $0.id == id }
        if config.defaultAIId == id {
            config.defaultAIId = config.aiConfigs.first?.id ?? ""
        }
    }
    
    // MARK: - Private
    
    private func saveConfig() {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: "app_config")
        }
    }
    
    private func saveWatchlist() {
        UserDefaults.standard.set(watchlistSymbols, forKey: "watchlist_symbols")
    }
}
