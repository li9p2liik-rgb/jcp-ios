import Foundation

// MARK: - AI Agent 模型
enum AgentRole: String, Codable, CaseIterable {
    case bull = "多头分析师"
    case bear = "空头怀疑论者"
    case quant = "技术量化专家"
    case macro = "宏观经济学家"
    case news = "市场情报员"
    
    var color: String {
        switch self {
        case .bull: return "#ef4444"
        case .bear: return "#22c55e"
        case .quant: return "#3b82f6"
        case .macro: return "#f59e0b"
        case .news: return "#8b5cf6"
        }
    }
    
    var systemPrompt: String {
        switch self {
        case .bull:
            return "你是一位资深多头分析师，擅长发现股票的上涨潜力和积极因素。从技术面、基本面、消息面等多角度寻找看多理由。"
        case .bear:
            return "你是一位谨慎的空头怀疑论者，擅长识别股票的风险因素和潜在问题。从估值过高、技术走弱、基本面恶化等角度提示风险。"
        case .quant:
            return "你是一位技术量化专家，精通技术分析理论和量化交易策略。分析K线形态、技术指标、量价关系等，给出量化视角的判断。"
        case .macro:
            return "你是一位宏观经济学家，擅长从宏观经济政策、行业周期、国际形势等宏观视角分析对股票的影响。"
        case .news:
            return "你是一位市场情报员，擅长搜集和解读最新的市场消息、新闻公告、舆情动态，分析消息面影响。"
        }
    }
}

struct Agent: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var role: AgentRole
    var avatar: String
    var color: String
    var instruction: String?
    var tools: [String]?
    var enabled: Bool
    
    static func == (lhs: Agent, rhs: Agent) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - 聊天消息
enum MsgType: String, Codable {
    case opening = "opening"
    case opinion = "opinion"
    case summary = "summary"
}

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: String
    let agentId: String
    var agentName: String?
    var role: String?
    var content: String
    var timestamp: Date
    var replyTo: String?
    var mentions: [String]?
    var round: Int?
    var msgType: MsgType?
    var error: String?
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
    
    init(agentId: String, agentName: String?, content: String, msgType: MsgType? = nil, round: Int? = nil) {
        self.id = UUID().uuidString
        self.agentId = agentId
        self.agentName = agentName
        self.content = content
        self.timestamp = Date()
        self.msgType = msgType
        self.round = round
    }
}

// MARK: - 会话
struct StockSession: Codable {
    let stockCode: String
    let stockName: String
    var lastUpdated: Date
    var messages: [ChatMessage]
    var position: StockPosition?
}

// MARK: - 策略
struct Strategy: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var agents: [Agent]
    var isActive: Bool
}
