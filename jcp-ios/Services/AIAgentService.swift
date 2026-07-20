import Foundation
import Combine

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
        User: \(query.isEmpty ? "Please analyze this stock" : query)
        As \(agent.role.rawValue) (\(agent.name)), provide analysis.
        """
        return callAI(system: sysPrompt, user: userPrompt, agent: agent)
    }

    func generateSummary(messages: [ChatMessage], stock: Stock) -> AnyPublisher<ChatMessage, Never> {
        let msgs = messages.map { "[\($0.agentName ?? "Agent")]: \($0.content)" }.joined(separator: "\n\n---\n\n")
        let userPrompt = """
        Discussion about \(stock.name)(\(stock.symbol)):
        \(msgs)
        Summarize viewpoints, consensus, disagreements, and suggestions.
        """
        return callAISimple(system: "You are a financial discussion summarizer.", user: userPrompt, agentName: "Summary")
    }

    private func callAI(system: String, user: String, agent: Agent) -> AnyPublisher<ChatMessage, Never> {
        return Future { [weak self] promise in
            guard let self = self else { return }
            let cfg = self.getActiveConfig()
            guard let url = URL(string: "\(cfg.baseURL)/chat/completions"), !cfg.apiKey.isEmpty else {
                let fb = self.fallbackResponse(agent: agent)
                promise(.success(ChatMessage(agentId: agent.id, agentName: agent.name, content: fb, msgType: .opinion, round: 1)))
                return
            }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("Bearer \(cfg.apiKey)", forHTTPHeaderField: "Authorization")
            let body: [String: Any] = [
                "model": cfg.modelName,
                "messages": [["role": "system", "content": system], ["role": "user", "content": user]],
                "temperature": cfg.temperature,
                "max_tokens": cfg.maxTokens,
                "top_p": cfg.topP
            ]
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)
            self.session.dataTask(with: req) { data, _, _ in
                var content = ""
                if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]], let first = choices.first,
                   let msg = first["message"] as? [String: Any], let text = msg["content"] as? String {
                    content = text
                } else { content = self.fallbackResponse(agent: agent) }
                promise(.success(ChatMessage(agentId: agent.id, agentName: agent.name, content: content, msgType: .opinion, round: 1)))
            }.resume()
        }.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    private func callAISimple(system: String, user: String, agentName: String) -> AnyPublisher<ChatMessage, Never> {
        return Future { [weak self] promise in
            guard let self = self else { return }
            let cfg = self.getActiveConfig()
            guard let url = URL(string: "\(cfg.baseURL)/chat/completions"), !cfg.apiKey.isEmpty else {
                promise(.success(ChatMessage(agentId: "summary", agentName: agentName, content: "Summary unavailable. Configure AI in Settings.", msgType: .summary)))
                return
            }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("Bearer \(cfg.apiKey)", forHTTPHeaderField: "Authorization")
            let body: [String: Any] = [
                "model": cfg.modelName,
                "messages": [["role": "system", "content": system], ["role": "user", "content": user]],
                "temperature": 0.5,
                "max_tokens": cfg.maxTokens,
                "top_p": cfg.topP
            ]
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)
            self.session.dataTask(with: req) { data, _, _ in
                var content = ""
                if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]], let first = choices.first,
                   let msg = first["message"] as? [String: Any], let text = msg["content"] as? String {
                    content = text
                } else { content = "Summary generation failed. Check AI configuration." }
                promise(.success(ChatMessage(agentId: "summary", agentName: agentName, content: content, msgType: .summary)))
            }.resume()
        }.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    private func getActiveConfig() -> (baseURL: String, apiKey: String, modelName: String, temperature: Double, maxTokens: Int, topP: Double) {
        let configs = ConfigService.shared.config.aiConfigs
        let defaultId = ConfigService.shared.config.defaultAIId
        if let active = configs.first(where: { $0.id == defaultId && !$0.apiKey.isEmpty }) ?? configs.first(where: { !$0.apiKey.isEmpty }) {
            return (active.baseURL, active.apiKey, active.modelName, active.temperature, active.maxTokens, active.topP)
        }
        return ("", "", "", 0.7, 2000, 1.0)
    }

    private func fallbackResponse(agent: Agent) -> String {
        return "## \(agent.name)\n\nConfigure your AI model in Settings to enable real-time analysis."
    }
}
