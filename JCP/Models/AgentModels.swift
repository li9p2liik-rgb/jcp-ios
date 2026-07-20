import Foundation

// MARK: - Agent Role

enum AgentRole: String, Codable, CaseIterable {
    case bull = "多头分析师"
    case bear = "空头怀疑论者"
    case quant = "技术量化专家"
    case macro = "宏观经济学家"
    case news = "市场情报员"
}

// MARK: - Agent Config

struct AgentConfig: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var role: String
    var avatar: String
    var color: String
    var instruction: String
    var tools: [String]
    var mcpServers: [String]
    var enabled: Bool
    var aiConfigID: String
}

// MARK: - Chat Message

enum MsgType: String, Codable {
    case opening
    case opinion
    case summary
}

struct ChatMessage: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    let agentId: String
    var agentName: String?
    var role: String?
    var content: String
    var timestamp: Date = Date()
    var replyTo: String?
    var mentions: [String]?
    var round: Int?
    var msgType: MsgType?
}

// MARK: - Moderator Decision

struct ModeratorDecision: Codable {
    let intent: String
    let selected: [String]
    let topic: String
    let opening: String
    let tasks: [String: String]
}

// MARK: - Discussion Entry

struct DiscussionEntry: Codable {
    let round: Int
    let agentId: String
    let agentName: String
    let role: String
    let content: String
}

// MARK: - Strategy

struct TradingStrategy: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var stockSymbol: String
    var stockName: String
    var direction: String // long / short
    var entryPrice: Double?
    var targetPrice: Double?
    var stopLoss: Double?
    var reason: String
    var status: StrategyStatus
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

enum StrategyStatus: String, Codable {
    case active
    case closed
    case pending
}

// MARK: - Session

struct ChatSession: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var title: String
    var stockSymbol: String
    var stockName: String
    var messages: [ChatMessage]
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}
