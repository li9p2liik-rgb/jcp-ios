import Foundation

/// OpenAI 兼容 API 实现，支持 OpenAI / DeepSeek / Kimi / GLM / 自定义 endpoint
actor OpenAICompatibleService: AILLMProtocol {

    private let config: AIConfig
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = .sortedKeys
        return e
    }()

    init(config: AIConfig) {
        self.config = config
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = TimeInterval(config.timeout)
        cfg.timeoutIntervalForResource = TimeInterval(config.timeout * 2)
        self.session = URLSession(configuration: cfg)
    }

    // MARK: - Non-streaming

    func generate(prompt: String, systemPrompt: String?, history: [ChatMessage]?) async throws -> String {
        let request = try buildRequest(prompt: prompt, systemPrompt: systemPrompt, history: history, stream: false)
        let (data, response) = try await session.data(for: request)
        try validateHTTP(response)
        let result = try decoder.decode(ChatCompletionResponse.self, from: data)
        guard let text = result.choices.first?.message.content else {
            throw APIError(message: "空响应", code: -1)
        }
        return text
    }

    // MARK: - Streaming

    func generateStream(
        prompt: String,
        systemPrompt: String?,
        history: [ChatMessage]?,
        onToken: @escaping (String) -> Void
    ) async throws -> String {
        let request = try buildRequest(prompt: prompt, systemPrompt: systemPrompt, history: history, stream: true)
        let (bytes, response) = try await session.bytes(for: request)
        try validateHTTP(response)

        var fullText = ""
        for try await line in bytes.lines {
            guard line.hasPrefix("data: ") else { continue }
            let jsonStr = String(line.dropFirst(6))
            if jsonStr == "[DONE]" { break }
            guard let data = jsonStr.data(using: .utf8),
                  let chunk = try? decoder.decode(ChatCompletionChunk.self, from: data),
                  let delta = chunk.choices.first?.delta.content else {
                continue
            }
            fullText += delta
            onToken(delta)
        }
        return fullText
    }

    // MARK: - Request building

    private func buildRequest(prompt: String, systemPrompt: String?, history: [ChatMessage]?, stream: Bool) throws -> URLRequest {
        // Use baseURL/chat/completions or fallback
        let base = config.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let url: URL
        if base.contains("/v1") || base.contains("/chat/completions") {
            url = URL(string: base.hasSuffix("/chat/completions") ? base : "\(base)/chat/completions")!
        } else {
            url = URL(string: "\(base)/v1/chat/completions")!
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")

        var messages: [ChatMessageJSON] = []

        // System message — skip if provider doesn't support it
        if !config.noSystemRole, let sys = systemPrompt, !sys.isEmpty {
            messages.append(ChatMessageJSON(role: "system", content: sys))
        }

        // History
        if let history {
            for msg in history {
                messages.append(ChatMessageJSON(role: "assistant", content: msg.content))
            }
        }

        // Current user prompt
        // If noSystemRole, prepend system instruction into user message
        var userContent = prompt
        if config.noSystemRole, let sys = systemPrompt, !sys.isEmpty {
            userContent = "\(sys)\n\n---\n\n\(prompt)"
        }
        messages.append(ChatMessageJSON(role: "user", content: userContent))

        let body = ChatCompletionRequest(
            model: config.modelName,
            messages: messages,
            temperature: config.temperature,
            maxTokens: config.maxTokens,
            stream: stream
        )
        req.httpBody = try encoder.encode(body)
        return req
    }

    private func validateHTTP(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError(message: "非 HTTP 响应", code: -1)
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError(message: "HTTP \(http.statusCode)", code: http.statusCode)
        }
    }
}

// MARK: - JSON structures for OpenAI API

private struct ChatMessageJSON: Codable {
    let role: String
    let content: String
}

private struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessageJSON]
    let temperature: Double
    let maxTokens: Int
    let stream: Bool

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature, stream
        case maxTokens = "max_tokens"
    }
}

private struct ChatCompletionResponse: Codable {
    let choices: [Choice]
    struct Choice: Codable {
        let message: Message
        struct Message: Codable {
            let content: String?
        }
    }
}

private struct ChatCompletionChunk: Codable {
    let choices: [Choice]
    struct Choice: Codable {
        let delta: Delta
        struct Delta: Codable {
            let content: String?
        }
    }
}
