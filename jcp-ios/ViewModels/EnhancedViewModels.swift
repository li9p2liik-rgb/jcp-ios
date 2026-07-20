import Foundation
import Combine

// MARK: - Settings ViewModel (Enhanced)
class SettingsViewModel: ObservableObject {
    @Published var aiConfigs: [AIConfig] = []
    @Published var config: FullAppConfig = .default()
    @Published var alertMessage = ""
    @Published var showAlert = false
    @Published var strategies: [StrategyData] = []
    @Published var activeStrategy: StrategyData?

    private let configService = ConfigService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadConfigs()
        loadStrategies()
    }

    func loadConfigs() {
        aiConfigs = configService.config.aiConfigs
        // Load full config from UserDefaults or use defaults
        if let data = UserDefaults.standard.data(forKey: "full_config"),
           let cfg = try? JSONDecoder().decode(FullAppConfig.self, from: data) {
            config = cfg
        }
    }

    func saveConfig(_ aiConfig: AIConfig) {
        configService.saveAIConfig(aiConfig)
        loadConfigs()
    }

    func deleteConfig(id: String) {
        configService.deleteAIConfig(id: id)
        loadConfigs()
    }

    func saveFullConfig() {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: "full_config")
        }
    }

    var defaultAI: AIConfig? {
        aiConfigs.first { $0.id == config.defaultAIId }
    }

    // Strategy management
    func loadStrategies() {
        strategies = [MockDataService.shared.generateDefaultStrategy()]
        activeStrategy = strategies.first
    }

    func addAgent(_ agent: StrategyAgent) {
        guard var strategy = activeStrategy else { return }
        strategy.agents.append(agent)
        activeStrategy = strategy
    }

    func removeAgent(id: String) {
        guard var strategy = activeStrategy else { return }
        strategy.agents.removeAll { $0.id == id }
        activeStrategy = strategy
    }

    func toggleAgent(id: String) {
        guard var strategy = activeStrategy else { return }
        if let idx = strategy.agents.firstIndex(where: { $0.id == id }) {
            strategy.agents[idx].enabled.toggle()
        }
        activeStrategy = strategy
    }
}

// MARK: - Telegraph ViewModel

class TelegraphViewModel: ObservableObject {
    @Published var telegraphs: [Telegraph] = []
    @Published var isLoading = false

    func loadTelegraphs() {
        isLoading = true
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) { [weak self] in
            let data = MockDataService.shared.generateTelegraphs()
            DispatchQueue.main.async {
                self?.telegraphs = data
                self?.isLoading = false
            }
        }
    }
}
