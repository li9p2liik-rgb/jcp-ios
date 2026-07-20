import Foundation

// MARK: - AI Provider

enum AIProvider: String, Codable, CaseIterable {
    case openai
    case gemini
    case vertexai
    case anthropic
    case deepseek
    case kimi
    case glm

    var displayName: String {
        switch self {
        case .openai: "OpenAI"
        case .gemini: "Gemini"
        case .vertexai: "Vertex AI"
        case .anthropic: "Anthropic"
        case .deepseek: "DeepSeek"
        case .kimi: "Kimi"
        case .glm: "GLM"
        }
    }
}

enum OpenAITokenParamMode: String, Codable {
    case auto
    case maxTokens = "max_tokens"
    case maxCompletionTokens = "max_completion_tokens"
}

// MARK: - AI Config

struct AIConfig: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var provider: AIProvider
    var baseURL: String
    var apiKey: String
    var modelName: String
    var maxTokens: Int = 4096
    var tokenParamMode: OpenAITokenParamMode = .auto
    var temperature: Double = 0.7
    var timeout: Int = 60
    var isDefault: Bool = false
    var useResponses: Bool = false
    var noSystemRole: Bool = false
    var project: String?
    var location: String?
    var credentialsJSON: String?
}

// MARK: - MCP Config

enum MCPTransportType: String, Codable {
    case http
    case sse
    case command
}

struct MCPServerConfig: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var transportType: MCPTransportType
    var endpoint: String = ""
    var command: String = ""
    var args: [String] = []
    var toolFilter: [String] = []
    var enabled: Bool = true
}

// MARK: - Agent Selection Style

enum AgentSelectionStyle: String, Codable {
    case balanced
    case conservative
    case aggressive
}

// MARK: - App Config

struct AppConfig: Codable, Equatable {
    var theme: String = "military"
    var candleColorMode: String = "red-up"
    var aiConfigs: [AIConfig] = []
    var defaultAIID: String = ""
    var strategyAIID: String = ""
    var moderatorAIID: String = ""
    var aiRetryCount: Int = 2
    var verboseAgentIO: Bool = false
    var agentSelectionStyle: AgentSelectionStyle = .balanced
    var enableSecondReview: Bool = false
    var mcpServers: [MCPServerConfig] = []
    var memory: MemoryConfig = MemoryConfig()
    var proxy: ProxyConfig = ProxyConfig()
}

// MARK: - Proxy Config

enum ProxyMode: String, Codable {
    case none
    case system
    case custom
}

struct ProxyConfig: Codable, Equatable {
    var mode: ProxyMode = .none
    var customURL: String = ""
}

// MARK: - Memory Config

struct MemoryConfig: Codable, Equatable {
    var enabled: Bool = true
    var aiConfigID: String = ""
    var maxRecentRounds: Int = 5
    var maxKeyFacts: Int = 20
    var maxSummaryLength: Int = 300
    var compressThreshold: Int = 10
}
