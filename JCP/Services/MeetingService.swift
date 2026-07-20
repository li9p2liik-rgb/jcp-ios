import Foundation

/// 财经会议室核心服务
@MainActor
final class MeetingService: ObservableObject {
    static let shared = MeetingService()

    @Published var isRunning = false
    @Published var currentRound = 0
    @Published var statusMessage = ""

    private let agentService = AgentService.shared
    private let configService = ConfigService.shared

    // MARK: - Run Meeting

    func runMeeting(
        stock: Stock,
        userQuery: String,
        onMessage: @escaping (ChatMessage) -> Void
    ) async throws {
        guard let aiConfig = configService.defaultAI else {
            throw APIError(message: "请先配置 AI 服务", code: -1)
        }
        guard agentService.enabledAgents().count > 0 else {
            throw APIError(message: "没有可用的分析专家", code: -1)
        }

        isRunning = true
        currentRound = 0
        defer { isRunning = false }

        let aiService = await AIServiceFactory.shared.service(for: aiConfig)

        // Step 1: Moderator 分析意图，选择专家
        statusMessage = "🧠 分析意图，选择专家..."
        let decision = try await analyzeIntent(
            ai: aiService, stock: stock, query: userQuery
        )
        let selectedAgents = agentService.agents.filter { decision.selected.contains($0.id) }

        // Send opening message
        let openingMsg = ChatMessage(
            agentId: "moderator",
            agentName: "小韭菜",
            role: "主持人",
            content: decision.opening,
            msgType: .opening
        )
        onMessage(openingMsg)

        if let topicMsgContent = formatTopic(decision: decision, agents: selectedAgents) {
            let topicMsg = ChatMessage(
                agentId: "moderator",
                agentName: "小韭菜",
                content: topicMsgContent,
                msgType: .opening
            )
            onMessage(topicMsg)
        }

        // Step 2: Multi-round discussion
        let maxRounds = 2
        var discussionHistory: [DiscussionEntry] = []

        for round in 1...maxRounds {
            currentRound = round
            statusMessage = "💬 第 \(round)/\(maxRounds) 轮讨论中..."

            for agent in selectedAgents {
                guard agent.enabled else { continue }
                let task = decision.tasks[agent.id] ?? "请从你的专业角度分析\(stock.name)"

                let prompt = buildAgentPrompt(
                    agent: agent, stock: stock, query: userQuery,
                    task: task, history: discussionHistory
                )

                statusMessage = "💬 \(agent.name) 分析中..."
                let response = try await aiService.generate(
                    prompt: prompt,
                    systemPrompt: agent.instruction,
                    history: nil
                )

                let msg = ChatMessage(
                    agentId: agent.id,
                    agentName: agent.name,
                    role: agent.role,
                    content: response,
                    round: round,
                    msgType: .opinion
                )
                onMessage(msg)

                discussionHistory.append(DiscussionEntry(
                    round: round, agentId: agent.id,
                    agentName: agent.name, role: agent.role,
                    content: response
                ))
            }
        }

        // Step 3: Summary
        statusMessage = "📝 总结讨论..."
        let summary = try await summarizeDiscussion(
            ai: aiService, stock: stock, query: userQuery,
            history: discussionHistory
        )
        let summaryMsg = ChatMessage(
            agentId: "moderator",
            agentName: "小韭菜",
            role: "主持人",
            content: summary,
            msgType: .summary
        )
        onMessage(summaryMsg)

        statusMessage = "✅ 讨论完成"
    }

    // MARK: - Private Methods

    private func analyzeIntent(
        ai: AILLMProtocol,
        stock: Stock,
        query: String
    ) async throws -> ModeratorDecision {
        let agents = agentService.enabledAgents()
        var prompt = """
        你是「财经会议室」的小韭菜，负责组织专家讨论。

        ## 当前股票
        \(stock.name)（\(stock.symbol)），现价 \(String(format: "%.2f", stock.price))，涨跌幅 \(String(format: "%.2f", stock.changePercent))%

        ## 老韭菜问题
        \(query)

        ## 可邀请的专家
        """
        for a in agents {
            prompt += "\n- \(a.name)（ID: \(a.id)）：\(a.role)"
        }
        prompt += """

        ## 你的任务
        1. 分析老韭菜问题的核心意图
        2. 选择 1-\(agents.count) 位最相关的专家
        3. 为每位选中专家制定明确的、与其专业匹配的分析任务
        4. 生成讨论议题和开场白

        ## 输出格式（仅输出JSON）
        {"intent":"意图","selected":["id1","id2"],"tasks":{"id1":"该专家分析任务","id2":"该专家分析任务"},"topic":"议题","opening":"开场白"}
        """

        let response = try await ai.generate(prompt: prompt, systemPrompt: nil, history: nil)
        return try parseModeratorDecision(response)
    }

    private func summarizeDiscussion(
        ai: AILLMProtocol,
        stock: Stock,
        query: String,
        history: [DiscussionEntry]
    ) async throws -> String {
        var prompt = """
        你是会议小韭菜，请总结讨论并给老韭菜结论。

        ## 股票：\(stock.name) (\(stock.symbol))

        ## 老韭菜问题
        \(query)

        ## 讨论记录
        """
        for entry in history {
            prompt += "\n【\(entry.agentName)（\(entry.role)）】\n\(entry.content)\n"
        }
        prompt += """
        ## 输出要求
        1. 核心结论（直接回答老韭菜）
        2. 各方观点摘要
        3. 综合建议

        控制在 400 字以内。
        """
        return try await ai.generate(prompt: prompt, systemPrompt: nil, history: nil)
    }

    private func buildAgentPrompt(
        agent: AgentConfig,
        stock: Stock,
        query: String,
        task: String,
        history: [DiscussionEntry]
    ) -> String {
        var prompt = "## 当前股票：\(stock.name)（\(stock.symbol)），现价 \(String(format: "%.2f", stock.price))\n\n"
        prompt += "## 你的分析任务\n\(task)\n\n"
        prompt += "## 用户原始问题\n\(query)\n\n"

        if !history.isEmpty {
            prompt += "## 前序讨论\n"
            for entry in history {
                prompt += "【\(entry.agentName)】\(entry.content.prefix(200))...\n"
            }
            prompt += "\n请结合其他专家的观点，从你的专业角度给出分析，可以赞同或质疑他人。\n"
        } else {
            prompt += "\n请从你的专业角度给出独立分析。\n"
        }
        return prompt
    }

    private func formatTopic(decision: ModeratorDecision, agents: [AgentConfig]) -> String? {
        var text = "**议题：\(decision.topic)**\n"
        text += "\n参与专家：\n"
        for agent in agents {
            text += "- \(agent.avatar) \(agent.name)（\(agent.role)）\n"
        }
        return text
    }

    private func parseModeratorDecision(_ content: String) throws -> ModeratorDecision {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        // Try extracting JSON from various patterns
        var jsonStr: String?

        if trimmed.hasPrefix("{") && trimmed.hasSuffix("}") {
            jsonStr = trimmed
        } else if let start = trimmed.firstIndex(of: "{"),
                  let end = trimmed.lastIndex(of: "}") {
            jsonStr = String(trimmed[start...end])
        }

        // Check for ```json block
        if jsonStr == nil {
            if let start = trimmed.range(of: "```json") {
                let after = trimmed[start.upperBound...]
                if let end = after.range(of: "```") {
                    jsonStr = String(after[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }

        guard let jsonStr else {
            throw APIError(message: "无法解析小韭菜决策", code: -1)
        }

        guard let data = jsonStr.data(using: .utf8) else {
            throw APIError(message: "决策 JSON 编码失败", code: -1)
        }

        let decision = try JSONDecoder().decode(ModeratorDecision.self, from: data)
        guard !decision.selected.isEmpty else {
            throw APIError(message: "小韭菜未选择任何专家", code: -1)
        }
        return decision
    }
}
