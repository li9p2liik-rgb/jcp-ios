import Foundation
import Combine

// Real AI service — reads user-configured API key/baseURL from ConfigService,
// calls OpenAI-compatible /v1/chat/completions, returns real responses.
class AIAgentService {
    static let shared = AIAgentService()
    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 60
        c.timeoutIntervalForResource = 120
        return URLSession(configuration: c)
    }()

    func generateAgentResponse(agent: Agent, stock: Stock, query: String, context: String) -> AnyPublisher<ChatMessage, Never> {
        let sysPrompt = agent.role.systemPrompt
        let userPrompt = """

        Context:
        \(context)

        User Question: \(query.isEmpty ? "Please analyze this stock" : query)

        As a \(agent.role.rawValue) (\(agent.name)), provide your analysis.
        """
        return callAI(system: sysPrompt, user: userPrompt, agent: agent)
    }

    func generateSummary(messages: [ChatMessage], stock: Stock) -> AnyPublisher<ChatMessage, Never> {
        let msgs = messages.map { "[\($0.agentName ?? "Agent")]: \($0.content)" }.joined(separator: "\n\n---\n\n")
        let userPrompt = """
        Below is a multi-agent discussion about \(stock.name)(\(stock.symbol)).
        Summarize key viewpoints, consensus, disagreements, and provide investment suggestions.

        Discussion:
        \(msgs)
        """
        return callAISimple(system: "You are a financial discussion summarizer.", user: userPrompt, agentName: "Summary")
    }

    // MARK: - Core API call

    private func callAI(system: String, user: String, agent: Agent) -> AnyPublisher<ChatMessage, Never> {
        return Future { [weak self] promise in
            guard let self = self else { return }
            let cfg = self.getActiveConfig()
            guard let url = URL(string: "\(cfg.baseURL)/chat/completions"),
                  !cfg.apiKey.isEmpty else {
                let fallback = self.fallbackResponse(agent: agent)
                promise(.success(ChatMessage(agentId: agent.id, agentName: agent.name, content: fallback, msgType: .opinion, round: 1)))
                return
            }

            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("Bearer \(cfg.apiKey)", forHTTPHeaderField: "Authorization")

            let body: [String: Any] = [
                "model": cfg.modelName,
                "messages": [
                    ["role": "system", "content": system],
                    ["role": "user", "content": user]
                ],
                "temperature": 0.7,
                "max_tokens": 2000
            ]
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)

            self.session.dataTask(with: req) { data, _, error in
                var content = ""
                if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let first = choices.first,
                   let msg = first["message"] as? [String: Any],
                   let text = msg["content"] as? String {
                    content = text
                } else {
                    content = self.fallbackResponse(agent: agent)
                }
                let message = ChatMessage(agentId: agent.id, agentName: agent.name, content: content, msgType: .opinion, round: 1)
                promise(.success(message))
            }.resume()
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    private func callAISimple(system: String, user: String, agentName: String) -> AnyPublisher<ChatMessage, Never> {
        return Future { [weak self] promise in
            guard let self = self else { return }
            let cfg = self.getActiveConfig()
            guard let url = URL(string: "\(cfg.baseURL)/chat/completions"),
                  !cfg.apiKey.isEmpty else {
                let fallback = "Summary unavailable. Configure an AI model in Settings."
                promise(.success(ChatMessage(agentId: "summary", agentName: agentName, content: fallback, msgType: .summary)))
                return
            }

            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("Bearer \(cfg.apiKey)", forHTTPHeaderField: "Authorization")

            let body: [String: Any] = [
                "model": cfg.modelName,
                "messages": [
                    ["role": "system", "content": system],
                    ["role": "user", "content": user]
                ],
                "temperature": 0.5,
                "max_tokens": 1500
            ]
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)

            self.session.dataTask(with: req) { data, _, _ in
                var content = ""
                if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let first = choices.first,
                   let msg = first["message"] as? [String: Any],
                   let text = msg["content"] as? String {
                    content = text
                } else {
                    content = "Summary generation failed. Check your AI configuration."
                }
                promise(.success(ChatMessage(agentId: "summary", agentName: agentName, content: content, msgType: .summary)))
            }.resume()
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    // MARK: - Config & Fallback

    private func getActiveConfig() -> (baseURL: String, apiKey: String, modelName: String) {
        let configs = ConfigService.shared.config.aiConfigs
        let defaultId = ConfigService.shared.config.defaultAIId
        if let active = configs.first(where: { $0.id == defaultId && !$0.apiKey.isEmpty })
            ?? configs.first(where: { !$0.apiKey.isEmpty }) {
            return (active.baseURL, active.apiKey, active.modelName)
        }
        return ("", "", "")
    }

    private func fallbackResponse(agent: Agent) -> String {
        switch agent.role {
        case .bull:
            return "## Bull Analysis\n\nNo AI model configured. Go to Settings → AI Config to add your API key.\n\nOnce configured, this agent will provide buy-side analysis for the selected stock."
        case .bear:
            return "## Risk Warning\n\nNo AI model configured. Go to Settings → AI Config to add your API key.\n\nOnce configured, this agent will identify risks and bearish signals."
        case .quant:
            return "## Quantitative Analysis\n\nNo AI model configured. Add your API key in Settings.\n\nOnce configured, technical indicators and quantitative metrics will be shown here."
        case .macro:
            return "## Macro View\n\nNo AI model configured. Add your API key in Settings.\n\nOnce configured, macroeconomic and policy analysis will appear here."
        case .news:
            return "## Market Intelligence\n\nNo AI model configured. Add your API key in Settings.\n\nOnce configured, news-driven analysis will appear here."
        }
    }
}