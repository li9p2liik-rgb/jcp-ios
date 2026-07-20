import Foundation

// MARK: - Full App Config (matching original JCP)
struct FullAppConfig: Codable {
    var aiConfigs: [AIConfig]
    var defaultAIId: String
    var moderatorAIId: String
    var memory: MemoryConfig
    var aiRetryCount: Int
    var verboseAgentIO: Bool
    var agentSelectionStyle: String
    var enableSecondReview: Bool
    var theme: String
    var watchlist: [String]
    var openClaw: OpenClawConfig
    var proxy: ProxyConfig
}

struct MemoryConfig: Codable {
    var enabled: Bool
    var maxRecentRounds: Int
    var maxKeyFacts: Int
    var maxSummaryLength: Int
    var compressThreshold: Int
    var aiConfigID: String
}

struct OpenClawConfig: Codable {
    var enabled: Bool
    var port: Int
    var apiKey: String
}

struct ProxyConfig: Codable {
    var enabled: Bool
    var host: String
    var port: Int
}

// MARK: - Strategy Model
struct StrategyAgent: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var role: String
    var avatar: String
    var color: String
    var instruction: String
    var tools: [String]
    var mcpServers: [String]
    var enabled: Bool
    
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: StrategyAgent, rhs: StrategyAgent) -> Bool { lhs.id == rhs.id }
}

struct StrategyData: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var aiConfigID: String
    var agents: [StrategyAgent]
    var isActive: Bool
    var prompts: [String]
    var systemPrompt: String
}

// MARK: - Research Report Model
struct ResearchReport: Identifiable, Codable {
    let id: String
    let title: String
    let orgName: String
    let rating: String
    let publishDate: String
    let stockCode: String
    let stockName: String
}

// MARK: - MCP Server Config
struct MCPServerConfigData: Identifiable, Codable {
    let id: String
    var name: String
    var transportType: String
    var endpoint: String
    var command: String
    var args: [String]
    var toolFilter: [String]
    var enabled: Bool
}

// MARK: - Update Info
struct UpdateInfo: Codable {
    let version: String
    let hasUpdate: Bool
    let downloadURL: String
    let releaseNotes: String
}

// MARK: - AI Model Extended Config
struct AIModelExtendedConfig: Codable {
    var temperature: Double
    var maxTokens: Int
    var topP: Double
    var frequencyPenalty: Double
    var presencePenalty: Double
}

// Defaults
extension FullAppConfig {
    static func `default`() -> FullAppConfig {
        FullAppConfig(
            aiConfigs: [],
            defaultAIId: "",
            moderatorAIId: "",
            memory: MemoryConfig(enabled: true, maxRecentRounds: 10, maxKeyFacts: 50, maxSummaryLength: 2000, compressThreshold: 30, aiConfigID: ""),
            aiRetryCount: 2,
            verboseAgentIO: false,
            agentSelectionStyle: "all",
            enableSecondReview: true,
            theme: "dark",
            watchlist: Constants.defaultWatchlist,
            openClaw: OpenClawConfig(enabled: false, port: 8080, apiKey: ""),
            proxy: ProxyConfig(enabled: false, host: "", port: 0)
        )
    }
}

extension MemoryConfig {
    static func `default`() -> MemoryConfig {
        MemoryConfig(enabled: true, maxRecentRounds: 10, maxKeyFacts: 50, maxSummaryLength: 2000, compressThreshold: 30, aiConfigID: "")
    }
}
