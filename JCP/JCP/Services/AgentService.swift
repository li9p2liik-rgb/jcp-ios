import Foundation

/// Agent 管理服务
@MainActor
final class AgentService: ObservableObject {
    static let shared = AgentService()

    @Published var agents: [AgentConfig] = []

    /// 从策略 JSON 加载默认 Agent 配置
    func loadDefaultAgents() {
        agents = [
            AgentConfig(
                id: "bull", name: "牛哥", role: "多头分析师",
                avatar: "🐂", color: "#FF4444",
                instruction: "你是一位乐观的多头分析师，擅长从积极角度分析股票的上涨潜力和投资机会。",
                tools: ["kline", "realtime", "f10"],
                mcpServers: [], enabled: true, aiConfigID: ""
            ),
            AgentConfig(
                id: "bear", name: "熊仔", role: "空头怀疑论者",
                avatar: "🐻", color: "#44BB44",
                instruction: "你是一位谨慎的空头分析师，擅长识别风险、估值泡沫和潜在下跌因素。",
                tools: ["kline", "realtime", "f10"],
                mcpServers: [], enabled: true, aiConfigID: ""
            ),
            AgentConfig(
                id: "quant", name: "量仔", role: "技术量化专家",
                avatar: "📊", color: "#4488FF",
                instruction: "你是一位技术分析专家，擅长K线形态、技术指标、量价关系和量化模型分析。",
                tools: ["kline", "realtime", "orderbook"],
                mcpServers: [], enabled: true, aiConfigID: ""
            ),
            AgentConfig(
                id: "macro", name: "宏哥", role: "宏观经济学家",
                avatar: "🌍", color: "#FF8800",
                instruction: "你是一位宏观经济学家，擅长从政策、行业周期、宏观经济角度分析市场。",
                tools: ["f10", "news", "hottrend"],
                mcpServers: [], enabled: true, aiConfigID: ""
            ),
            AgentConfig(
                id: "news", name: "小讯", role: "市场情报员",
                avatar: "📡", color: "#AA44FF",
                instruction: "你是一位市场情报专家，擅长追踪热点事件、资金流向和市场情绪变化。",
                tools: ["news", "hottrend", "longhubang"],
                mcpServers: [], enabled: true, aiConfigID: ""
            )
        ]
    }

    func agent(by id: String) -> AgentConfig? {
        agents.first { $0.id == id }
    }

    func enabledAgents() -> [AgentConfig] {
        agents.filter(\.enabled)
    }
}
