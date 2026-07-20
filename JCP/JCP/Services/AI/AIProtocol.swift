import Foundation

/// 通用 AI 大模型调用协议
protocol AILLMProtocol {
    /// 非流式生成
    func generate(prompt: String, systemPrompt: String?, history: [ChatMessage]?) async throws -> String

    /// 流式生成，通过回调逐字返回
    func generateStream(
        prompt: String,
        systemPrompt: String?,
        history: [ChatMessage]?,
        onToken: @escaping (String) -> Void
    ) async throws -> String
}

/// AI 服务工厂
actor AIServiceFactory {
    static let shared = AIServiceFactory()

    private var services: [String: AILLMProtocol] = [:]

    func service(for config: AIConfig) -> AILLMProtocol {
        if let existing = services[config.id] {
            return existing
        }
        let service = OpenAICompatibleService(config: config)
        services[config.id] = service
        return service
    }

    func evict(id: String) {
        services.removeValue(forKey: id)
    }
}
