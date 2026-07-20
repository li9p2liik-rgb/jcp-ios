import Foundation

/// 应用配置持久化服务
@MainActor
final class ConfigService: ObservableObject {
    static let shared = ConfigService()

    @Published var config: AppConfig

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

    /// 显式保存到磁盘——struct 嵌套数组不会自动触发 didSet
    func saveToDisk() {
        guard let data = try? JSONEncoder().encode(config) else {
            print("[ConfigService] 编码配置失败")
            return
        }
        do {
            try data.write(to: storageURL, options: .atomic)
            print("[ConfigService] 配置已保存: \(storageURL.path)")
        } catch {
            print("[ConfigService] 写入文件失败: \(error)")
        }
    }

    // MARK: - AI Config

    func addAIConfig(_ aiConfig: AIConfig) {
        config.aiConfigs.append(aiConfig)
        if config.defaultAIID.isEmpty { config.defaultAIID = aiConfig.id }
        saveToDisk()
    }

    func updateAIConfig(_ aiConfig: AIConfig) {
        guard let idx = config.aiConfigs.firstIndex(where: { $0.id == aiConfig.id }) else { return }
        config.aiConfigs[idx] = aiConfig
        saveToDisk()
    }

    func deleteAIConfig(id: String) {
        config.aiConfigs.removeAll { $0.id == id }
        if config.defaultAIID == id {
            config.defaultAIID = config.aiConfigs.first?.id ?? ""
        }
        saveToDisk()
    }

    func setDefaultAI(id: String) {
        config.defaultAIID = id
        saveToDisk()
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
