import Foundation

/// 应用配置持久化服务
@MainActor
final class ConfigService: ObservableObject {
    static let shared = ConfigService()

    @Published var config: AppConfig {
        didSet { save() }
    }

    private let storageURL: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        storageURL = docs.appendingPathComponent("config.json")
        if let data = try? Data(contentsOf: storageURL),
           let decoded = try? JSONDecoder().decode(AppConfig.self, from: data) {
            self.config = decoded
        } else {
            self.config = AppConfig()
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(config) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }

    // MARK: - Convenience accessors

    var activeAIConfigs: [AIConfig] {
        config.aiConfigs.filter { !$0.apiKey.isEmpty }
    }

    var defaultAI: AIConfig? {
        config.aiConfigs.first { $0.id == config.defaultAIID && !$0.apiKey.isEmpty }
            ?? activeAIConfigs.first
    }

    var moderatorAI: AIConfig? {
        config.aiConfigs.first { $0.id == config.moderatorAIID && !$0.apiKey.isEmpty }
            ?? defaultAI
    }

    func aiConfig(by id: String) -> AIConfig? {
        config.aiConfigs.first { $0.id == id }
    }
}
